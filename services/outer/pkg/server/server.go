package server

import (
	innerc "github.com/angelini/mesh/services/inner/pkg/client"
	pb "github.com/angelini/mesh/services/outer/internal/outerpb"
	"github.com/angelini/mesh/services/outer/pkg/api"
	grpc_middleware "github.com/grpc-ecosystem/go-grpc-middleware"
	grpc_zap "github.com/grpc-ecosystem/go-grpc-middleware/logging/zap"
	grpc_recovery "github.com/grpc-ecosystem/go-grpc-middleware/recovery"
	"go.uber.org/zap"
	"google.golang.org/grpc"
)

func NewServer(log *zap.Logger, innerClient *innerc.Client) *grpc.Server {
	grpcServer := grpc.NewServer(
		grpc.UnaryInterceptor(
			grpc_middleware.ChainUnaryServer(
				grpc_recovery.UnaryServerInterceptor(),
				grpc_zap.UnaryServerInterceptor(log),
			),
		),
		grpc.StreamInterceptor(
			grpc_middleware.ChainStreamServer(
				grpc_recovery.StreamServerInterceptor(),
				grpc_zap.StreamServerInterceptor(log),
			),
		),
	)

	outerApi := api.NewOuterApi(log, innerClient)
	pb.RegisterOuterServer(grpcServer, outerApi)

	return grpcServer
}
