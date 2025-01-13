package main

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"sync"
	"time"
)

type Config struct {
	BaseDir          string
	MaxConcurrency   int
	TargetRegex      string
	CacheDir         string
	CacheAppsDir     string
	CacheShaFilename string
	OutDir           string
	KustomizePath    string
	KustomizeTimeout time.Duration
}

var DefaultConfig = &Config{
	BaseDir:          "kubernetes/",
	MaxConcurrency:   10,
	TargetRegex:      "^apps/[^/]+/(production|staging)$",
	CacheDir:         "/tmp/pkustomize/cache/",
	CacheAppsDir:     "manifests/",
	CacheShaFilename: "sha",
	OutDir:           "/tmp/pkustomize/out/",
	KustomizePath:    "kustomize",
	KustomizeTimeout: 1 * time.Minute,
}

type AppPath string // path that matches the TargetRegex

func main() {
	conf := DefaultConfig
	allApps, err := getAllApps(conf)
	if err != nil {
		panic(err)
	}
	apps, err := appsNotCached(allApps, conf)
	if err != nil {
		panic(err)
	}
	if err := CopyFromCache(conf); err != nil {
		slog.Error(err.Error())
	}
	if err := BuildApps(apps, conf); err != nil {
		slog.Error(err.Error())
	}
	if err := WriteCurrentCommit(conf); err != nil {
		slog.Error(err.Error())
	}
}

func getAllApps(c *Config) ([]AppPath, error) {
	apps := make([]AppPath, 0)
	err := filepath.WalkDir(".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return fmt.Errorf("failed to walk dirs: %w", err)
		}
		if !d.IsDir() {
			return nil
		}
		match, err := regexp.MatchString(c.TargetRegex, path)
		if err != nil {
			return fmt.Errorf("failed to get matchString of %s: %w", path, err)
		}
		if match {
			apps = append(apps, AppPath(path))
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to find files: %w", err)
	}
	return apps, nil
}

func getCurrentCommitSHA() (string, error) {
	cmd := exec.Command("git", "show", "--format=%H", "--no-patch")
	h, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get current commit sha: %w", err)
	}
	return strings.TrimSuffix(string(h), "\n"), nil
}

func getCacheSha(c *Config) (string, error) {
	sha, err := os.ReadFile(path.Join(c.CacheDir, c.CacheShaFilename))
	if err != nil {
		return "", fmt.Errorf("failed to read sha from file: %w", err)
	}
	valid, err := regexp.Match("[a-z0-9]+", sha)
	if err != nil {
		return "", fmt.Errorf("failed to validate sha: %w", err)
	}
	if !valid {
		return "", fmt.Errorf("sha in cache file is not valid: %s", sha)
	}
	return string(sha), nil
}

func getDiffsFrom(sha string) ([]string, error) {
	cmd := exec.Command("git", "diff", "--name-only", string(sha))
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, fmt.Errorf("failed to get stdout: %w", err)
	}
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("failed to start cmd: %w", err)
	}
	diffBytes, err := io.ReadAll(stdout)
	if err != nil {
		return nil, fmt.Errorf("failed to read stdout: %w", err)
	}
	diffs := strings.Split(string(diffBytes), "\n")
	return diffs, nil
}

func getCachedApps(c *Config) ([]AppPath, error) {
	dirs := make([]AppPath, 0)
	root := path.Join(c.CacheDir, c.CacheAppsDir) + string(os.PathSeparator)
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() {
			return nil
		}
		appPath := path[len(root):]
		match, err := regexp.MatchString(c.TargetRegex, appPath)
		if err != nil {
			return fmt.Errorf("failed to match regexp of %s: %w", path, err)
		}
		if match {
			dirs = append(dirs, AppPath(appPath))
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get apps dirs: %w", err)
	}
	return dirs, nil
}

func getModifiedApps(c *Config) ([]AppPath, error) {
	sha, err := getCacheSha(c)
	if err != nil {
		return nil, fmt.Errorf("failed to read sha from file: %w", err)
	}
	regStr := c.TargetRegex
	if strings.HasSuffix(c.TargetRegex, "$") {
		regStr = c.TargetRegex[:len(c.TargetRegex)-1]
	}
	targetReg, err := regexp.Compile(regStr)
	if err != nil {
		return nil, fmt.Errorf("failed to compile target regex: %w", err)
	}
	diffs, err := getDiffsFrom(sha)
	if err != nil {
		return nil, fmt.Errorf("failed to get diff: %w", err)
	}
	apps := make([]AppPath, 0)
	for _, diff := range diffs {
		if !strings.HasPrefix(diff, c.BaseDir) {
			continue
		}
		appFile := strings.TrimPrefix(diff, c.BaseDir)
		matches := targetReg.FindAllString(appFile, -1)
		if matches == nil {
			continue
		}
		app := matches[0]
		apps = append(apps, AppPath(app))
	}
	return apps, nil
}

func appsNotCached(allApps []AppPath, c *Config) ([]AppPath, error) {
	shaFilePath := path.Join(c.CacheDir, c.CacheShaFilename)
	if _, err := os.Stat(shaFilePath); os.IsNotExist(err) {
		return allApps, nil
	}
	notCached := make([]AppPath, 0, len(allApps))
	cachedApps, err := getCachedApps(c)
	if err != nil {
		return nil, fmt.Errorf("failed to get cached apps: %w", err)
	}
	for _, app := range allApps {
		if !slices.Contains(cachedApps, app) {
			notCached = append(notCached, app)
		}
	}
	modifiedApps, err := getModifiedApps(c)
	if err != nil {
		return nil, fmt.Errorf("failed to get modified apps: %w", err)
	}
	notCached = append(notCached, modifiedApps...)
	return notCached, nil
}

func CopyFromCache(c *Config) error {
	return exec.Command("cp", "-R", path.Join(c.CacheDir, c.CacheAppsDir), c.OutDir).Run()
}

func WriteCurrentCommit(c *Config) error {
	if err := os.MkdirAll(c.CacheDir, 0744); err != nil {
		return fmt.Errorf("failed to make cache dir: %w", err)
	}
	shaFile, err := os.Create(path.Join(c.CacheDir, c.CacheShaFilename))
	if err != nil {
		return fmt.Errorf("failed to create sha file: %w", err)
	}
	sha, err := getCurrentCommitSHA()
	if err != nil {
		return fmt.Errorf("failed to get commit sha: %w", err)
	}
	if _, err := shaFile.WriteString(sha); err != nil {
		return fmt.Errorf("failed to write to sha file: %w", err)
	}
	return nil
}

func BuildApps(apps []AppPath, c *Config) error {
	var wg sync.WaitGroup
	sem := make(chan struct{}, c.MaxConcurrency)
	ctx, cancel := context.WithTimeout(context.Background(), c.KustomizeTimeout)
	defer cancel()
	errchan := make(chan error, 1)
	for _, app := range apps {
		wg.Add(1)
		sem <- struct{}{}
		go func() {
			defer wg.Done()
			defer func() { <-sem }()

			select {
			case <-ctx.Done():
				return
			default:
				err := Kustomize(ctx, app, c)
				if err != nil {
					errchan <- err
					cancel()
					return
				}
			}
		}()
	}
	go func() {
		wg.Wait()
		close(errchan)
	}()
	if err := <-errchan; err != nil {
		return fmt.Errorf("failed to build apps: %w", err)
	}
	return nil
}

func Kustomize(_ context.Context, app AppPath, c *Config) error {
	slog.Info(fmt.Sprintf("building %s", app))
	cmd := exec.Command("kustomize", "build", string(app))
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to get stdout: %w", err)
	}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start cmd: %w", err)
	}
	outDir := path.Join(c.OutDir, string(app))
	if err := os.MkdirAll(outDir, 0744); err != nil {
		return fmt.Errorf("failed to make out dir: %w", err)
	}
	cacheDir := path.Join(c.CacheDir, c.CacheAppsDir, string(app))
	if err := os.MkdirAll(cacheDir, 0744); err != nil {
		return fmt.Errorf("failed to make cache dir: %w", err)
	}
	out, err := os.Create(path.Join(outDir, "out.yaml"))
	if err != nil {
		return fmt.Errorf("failed to create out file: %w", err)
	}
	cache, err := os.Create(path.Join(cacheDir, "cache.yaml"))
	if err != nil {
		return fmt.Errorf("failed to create cache dir: %w", err)
	}
	if _, err := io.Copy(cache, stdout); err != nil {
		return fmt.Errorf("failed to write to cache: %w", err)
	}
	if _, err := io.Copy(out, stdout); err != nil {
		return fmt.Errorf("failed to write to out: %w", err)
	}
	return nil
}
