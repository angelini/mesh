package api

import (
	"context"

	"github.com/angelini/mesh/services/inner/internal/pb"
	"go.uber.org/zap"
)

type InnerApi struct {
	pb.UnimplementedInnerServer

	log *zap.Logger
}

func NewInnerApi(log *zap.Logger) *InnerApi {
	return &InnerApi{
		log: log,
	}
}

func (a *InnerApi) Reverse(ctx context.Context, req *pb.ReverseRequest) (*pb.ReverseResponse, error) {
	runes := []rune(req.Input)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}

	return &pb.ReverseResponse{
		Output: string(runes),
	}, nil
}
