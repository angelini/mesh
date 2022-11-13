package cmd

import (
	"fmt"
	"net"

	"github.com/angelini/mesh/services/outer/pkg/server"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

func NewCmdApi() *cobra.Command {
	var port int

	cmd := &cobra.Command{
		Use:   "api",
		Short: "Billing data collector API",
		RunE: func(cmd *cobra.Command, _ []string) error {
			ctx := cmd.Context()
			log := ctx.Value(logKey).(*zap.Logger)

			socket, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
			if err != nil {
				return fmt.Errorf("failed to listen on TCP port %d: %w", port, err)
			}

			log.Info("start outer", zap.Int("port", port))
			server := server.NewServer(log)
			return server.Serve(socket)
		},
	}

	cmd.PersistentFlags().IntVarP(&port, "port", "p", 5152, "Api port")

	return cmd
}
