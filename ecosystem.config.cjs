/** pm2：xiaozhi-mcp-proxy（部署目录 /data/www/xiaozhi-mcp-proxy） */
module.exports = {
  apps: [
    {
      name: "xiaozhi-proxy",
      script: "mcp_pipe.py",
      args: "mcp_stdio_client.py",
      interpreter: process.env.PYTHON_BIN || "python3.11",
      cwd: __dirname,
      instances: 1,
      autorestart: true,
      max_restarts: 20,
      min_uptime: "10s",
      env: {
        MCP_ENDPOINT: process.env.MCP_ENDPOINT || process.env.XIAOZHI_MCP_ENDPOINT || "",
        MCP_URL: process.env.MCP_URL || "http://127.0.0.1:3100/mcp",
      },
    },
  ],
};
