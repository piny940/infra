package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"

	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Debug bool   `default:"false"`
	Port  string `default:"8080"`
	Token string `required:"true"`
}

func main() {
	godotenv.Load()
	var conf Config
	if err := envconfig.Process("APP", &conf); err != nil {
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

	server := http.Server{
		Addr: ":" + conf.Port,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path != "/" {
				http.NotFound(w, r)
				slog.Info(fmt.Sprintf("Not found: %s", r.URL.Path))
				return
			}
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
			w.Write([]byte("Hello, World!"))
		}),
	}

	slog.Info(fmt.Sprintf("Starting server http://localhost:%s", conf.Port))
	if err := server.ListenAndServe(); err != nil {
		panic(err)
	}
}
