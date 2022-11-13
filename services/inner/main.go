package main

import (
	"os"

	"github.com/angelini/mesh/services/inner/cmd"
)

func main() {
	err := cmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}
