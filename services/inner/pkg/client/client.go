package client

import (
	"context"
	"fmt"
	"time"

	pb "github.com/angelini/mesh/services/inner/internal/innerpb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type Client struct {
	conn  *grpc.ClientConn
	inner pb.InnerClient
}

func NewClient(ctx context.Context, server string) (*Client, error) {
	connectCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()

	conn, err := grpc.DialContext(connectCtx, server,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, fmt.Errorf("could not connect to %s: %w", server, err)
	}

	return &Client{conn: conn, inner: pb.NewInnerClient(conn)}, nil
}

func (c *Client) Reverse(ctx context.Context, input string) (string, error) {
	resp, err := c.inner.Reverse(ctx, &pb.ReverseRequest{Input: input})
	if err != nil {
		return "", fmt.Errorf("error calling Reverse: %w", err)
	}
	return resp.Output, nil
}
