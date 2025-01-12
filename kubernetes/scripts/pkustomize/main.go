package main

import (
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path"
	"sync"
)

type Env string

const (
	EnvProduction Env = "production"
	EnvStaging    Env = "staging"
)

var AllEnvs = []Env{EnvProduction, EnvStaging}

const (
	AppDir         = "apps"
	MaxConcurrency = 10
)

func main() {
	files, err := os.ReadDir(AppDir)
	if err != nil {
		panic(err)
	}
	var wg sync.WaitGroup
	sem := make(chan struct{}, MaxConcurrency)

	for _, file := range files {
		if !file.IsDir() {
			continue
		}
		for _, env := range AllEnvs {
			wg.Add(1)
			sem <- struct{}{}
			go func() {
				defer wg.Done()
				defer func() { <-sem }()

				f := path.Join(AppDir, file.Name(), string(env))
				slog.Info(fmt.Sprintf("Building %s", f))
				outDir := path.Join("tmp", "kustomize", "out", file.Name())
				if err := os.MkdirAll(outDir, 0744); err != nil {
					slog.Error(fmt.Sprintf("failed to mkdir %s: %v", outDir, err))
					return
				}
				outPath := path.Join(outDir, string(env)+".yaml")
				out, err := os.Create(outPath)
				if err != nil {
					slog.Error(fmt.Sprintf("failed to create file %s: %v", outPath, err))
					return
				}
				cmd := exec.Command("kustomize", "build", f)
				stdout, err := cmd.StdoutPipe()
				if err != nil {
					slog.Error(fmt.Sprintf("failed to get stdout: %v", err))
					return
				}
				if err := cmd.Start(); err != nil {
					slog.Error(fmt.Sprintf("failed to start cmd: %v", err))
					return
				}
				if _, err := io.Copy(out, stdout); err != nil {
					slog.Error(fmt.Sprintf("Error has occurred: %v", err))
					return
				}
			}()
		}
	}
	wg.Wait()
}
