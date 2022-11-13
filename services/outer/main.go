package main

import (
	"os"

	"github.com/angelini/mesh/services/outer/cmd"
)

func main() {
	err := cmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}
