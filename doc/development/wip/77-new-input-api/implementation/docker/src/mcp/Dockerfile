FROM ghcr.io/nzrsky/lsp-mcp-server:latest

RUN apk add --no-cache socat lua-language-server

ENTRYPOINT ["socat", "TCP-LISTEN:500,fork,reuseaddr"]
CMD ["EXEC:'/lsp-mcp-server'"]

## or should be 'workspace'?
VOLUME /repo

