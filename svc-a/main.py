import os
from fastapi import FastAPI
from ddtrace import tracer

# Get Datadog tracer instance
# The tracer is automatically configured from environment variables.
# DD_AGENT_HOST: The hostname or IP address of the Datadog Agent.
# DD_ENV: The environment name (e.g., prod, staging).
# DD_SERVICE: The name of your service.
# DD_VERSION: The version of your service.

app = FastAPI()

@tracer.wrap(name="get.root.data", service="service-a-data")
def get_data_from_source():
    """
    A dummy function to simulate fetching data.
    A custom span will be created for this function in Datadog.
    """
    return {"message": "Hello from Service A!"}

@app.get("/")
def read_root():
    """
    Root endpoint for Service A.
    It calls a function that has custom tracing.
    """
    # The main logic of the endpoint.
    # We are calling our custom traced function here.
    data = get_data_from_source()
    return data

@app.get("/health")
def health_check():
    """
    A simple health check endpoint.
    """
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    # This block is for local development.
    # Uvicorn is a lightning-fast ASGI server.
    uvicorn.run(app, host="0.0.0.0", port=8000)