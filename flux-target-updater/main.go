package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"

	fluxv1 "github.com/fluxcd/source-controller/api/v1"
	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

type Config struct {
	Debug bool   `default:"false"`
	Port  string `default:"8080"`
	Token string `required:"true"`
}

const FIELD_MANAGER = "com.piny940.flux-target-updater"

var k8sClient kubernetes.Interface
var dynamicClient dynamic.Interface
var conf = &Config{}

func main() {
	godotenv.Load()
	if err := envconfig.Process("APP", conf); err != nil {
		panic(err)
	}
	logLevel := slog.LevelInfo
	if conf.Debug {
		logLevel = slog.LevelDebug
	}
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: logLevel,
	})))
	slog.Debug(fmt.Sprintf("conf: %+v", conf))

	var err error
	k8sClient, err = newClient(conf)
	if err != nil {
		panic(err)
	}
	dynamicClient, err = newDynamicClient(conf)
	if err != nil {
		panic(err)
	}

	server := http.Server{
		Addr: ":" + conf.Port,
	}
	http.HandleFunc("/", healthz)
	http.HandleFunc("/branch", handleBranch)

	slog.Info(fmt.Sprintf("Starting server http://localhost:%s", conf.Port))
	if err := server.ListenAndServe(); err != nil {
		panic(err)
	}
}

func newClient(conf *Config) (kubernetes.Interface, error) {
	var config *rest.Config
	var err error
	if conf.Debug {
		configPath := filepath.Join(homedir.HomeDir(), ".kube", "config")
		config, err = clientcmd.BuildConfigFromFlags("", configPath)
	} else {
		config, err = rest.InClusterConfig()
	}
	if err != nil {
		return nil, err
	}

	client, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func newDynamicClient(conf *Config) (dynamic.Interface, error) {
	var config *rest.Config
	var err error
	if conf.Debug {
		configPath := filepath.Join(homedir.HomeDir(), ".kube", "config")
		config, err = clientcmd.BuildConfigFromFlags("", configPath)
	} else {
		config, err = rest.InClusterConfig()
	}
	if err != nil {
		return nil, err
	}

	client, err := dynamic.NewForConfig(config)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func healthz(w http.ResponseWriter, r *http.Request) {
	slog.Info(fmt.Sprintf("%s %s", r.Method, r.URL.Path))
	w.Write([]byte("ok"))
}

func handleBranch(w http.ResponseWriter, r *http.Request) {
	slog.Info(fmt.Sprintf("%s %s", r.Method, r.URL.Path))
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		slog.Info(fmt.Sprintf("Method not allowed: %s", r.Method))
		return
	}
	if r.Header.Get("Authorization") != "Bearer "+conf.Token {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		slog.Info(fmt.Sprintf("Unauthorized: %s", r.Header.Get("Authorization")))
		return
	}
	if r.Header.Get("Content-Type") != "application/json" {
		http.Error(w, "Unsupported Media Type", http.StatusUnsupportedMediaType)
		slog.Info(fmt.Sprintf("Unsupported Media Type: %s", r.Header.Get("Content-Type")))
		return
	}
	decoder := json.NewDecoder(r.Body)

	var data map[string]interface{}
	if err := decoder.Decode(&data); err != nil {
		http.Error(w, "Only Json format acceptable", http.StatusBadRequest)
		slog.Info(fmt.Sprintf("Bad Request: %s", err))
		return
	}
	branch := data["ref"].(string)
	target := data["name"].(string)
	ns := data["namespace"].(string)
	err := updateTarget(r.Context(), branch, target, ns)
	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		slog.Error(fmt.Sprintf("Internal Server Error: %v", err))
		return
	}

	slog.Info(fmt.Sprintf("Successfully updated branch target of %s in namespace %s to %s", target, ns, branch))
	w.Write([]byte(fmt.Sprintf("Successfully updated branch target of %s in namespace %s to %s", target, ns, branch)))
}

func updateTarget(ctx context.Context, branch, target, ns string) error {
	slog.Info(fmt.Sprintf("Updating target %s to %s in namespace %s", branch, target, ns))
	gvr := schema.GroupVersionResource{
		Group:    fluxv1.GroupVersion.Group,
		Version:  fluxv1.GroupVersion.Version,
		Resource: "gitrepositories",
	}
	obj, err := dynamicClient.Resource(gvr).Namespace(ns).Get(ctx, target, metav1.GetOptions{})
	if err != nil {
		slog.Error(fmt.Sprintf("Failed to get GitRepository %s in namespace %s: %v", target, ns, err))
		return err
	}
	current := &fluxv1.GitRepository{}
	err = runtime.DefaultUnstructuredConverter.FromUnstructured(obj.Object, current)
	if err != nil {
		slog.Error(fmt.Sprintf("Failed to convert Unstructured to GitRepository: %v", err))
		return err
	}
	if current.Spec.Reference.Branch == branch {
		slog.Info(fmt.Sprintf("Target %s is already on branch %s", target, branch))
		return nil
	}
	patchObj := &unstructured.Unstructured{Object: map[string]interface{}{
		"spec": map[string]interface{}{
			"ref": map[string]interface{}{
				"branch": branch,
			},
		},
	}}
	json, err := patchObj.MarshalJSON()
	if err != nil {
		slog.Error(fmt.Sprintf("Failed to marshal JSON: %v", err))
		return err
	}
	_, err = dynamicClient.Resource(gvr).Namespace(ns).
		Patch(ctx, target, types.MergePatchType, json, metav1.PatchOptions{
			FieldManager: FIELD_MANAGER,
		})
	if err != nil {
		slog.Error(fmt.Sprintf("Failed to patch GitRepository %s in namespace %s: %v", target, ns, err))
		return err
	}
	return nil
}
