package api

import (
	"context"
	"fmt"

	"github.com/angelini/mesh/services/outer/internal/pb"
	"go.uber.org/zap"
)

type OuterApi struct {
	pb.UnimplementedOuterServer

	log *zap.Logger
}

func NewOuterApi(log *zap.Logger) *OuterApi {
	return &OuterApi{
		log: log,
	}
}

func (a *OuterApi) Quote(ctx context.Context, req *pb.QuoteRequest) (*pb.QuoteResponse, error) {
	return &pb.QuoteResponse{
		Output: fmt.Sprintf("<<%s>>", req.Input),
	}, nil
}
