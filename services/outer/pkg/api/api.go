package api

import (
	"context"
	"fmt"

	innerc "github.com/angelini/mesh/services/inner/pkg/client"
	pb "github.com/angelini/mesh/services/outer/internal/outerpb"
	"go.uber.org/zap"
)

type OuterApi struct {
	pb.UnimplementedOuterServer

	log   *zap.Logger
	inner *innerc.Client
}

func NewOuterApi(log *zap.Logger, innerClient *innerc.Client) *OuterApi {
	return &OuterApi{
		log:   log,
		inner: innerClient,
	}
}

func (a *OuterApi) Quote(ctx context.Context, req *pb.QuoteRequest) (*pb.QuoteResponse, error) {
	a.log.Info("Quote", zap.String("input", req.Input))

	reversed, err := a.inner.Reverse(ctx, req.Input)
	if err != nil {
		return nil, err
	}

	return &pb.QuoteResponse{
		Output: fmt.Sprintf("<<%s>>", reversed),
	}, nil
}
