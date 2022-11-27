package cmd

import (
	"fmt"
	"net"

	innerc "github.com/angelini/mesh/services/inner/pkg/client"
	"github.com/angelini/mesh/services/outer/pkg/server"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

func NewCmdApi() *cobra.Command {
	var (
		port  int
		inner string
	)

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

			innerClient, err := innerc.NewClient(ctx, inner)
			if err != nil {
				return err
			}

			log.Info("start outer", zap.Int("port", port), zap.String("inner", inner))
			server := server.NewServer(log, innerClient)
			return server.Serve(socket)
		},
	}

	cmd.PersistentFlags().IntVarP(&port, "port", "p", 5152, "Api port")
	cmd.PersistentFlags().StringVarP(&inner, "inner", "i", "", "Inner service URI")

	return cmd
}
