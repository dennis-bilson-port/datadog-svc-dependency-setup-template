import os
import requests
from fastapi import FastAPI, HTTPException
from ddtrace import tracer

app = FastAPI()

# The URL for Service A is retrieved from an environment variable.
# In Kubernetes, this will be http://service-a
SERVICE_A_URL = os.getenv("SERVICE_A_URL", "http://localhost:8000")

@app.get("/call-a")
def call_service_a():
    """
    This endpoint calls Service A.
    ddtrace automatically instruments the 'requests' library,
    so this call will be part of the distributed trace.
    """
    try:
        # Custom span to trace the business logic of calling service A
        with tracer.trace("service_b.call_service_a_logic") as span:
            span.set_tag("service.a.url", SERVICE_A_URL)

            response = requests.get(f"{SERVICE_A_URL}/")
            response.raise_for_status()  # Raise an exception for bad status codes

            data = response.json()
            span.set_tag("service.a.response", str(data))

            return {"data": data}

    except requests.exceptions.RequestException as e:
        # Log the error and return an informative error message
        tracer.current_span().set_exc_info(type(e), e, e.__traceback__)
        raise HTTPException(status_code=500, detail=f"Error calling Service A: {e}")

@app.get("/health")
def health_check():
    """
    A simple health check endpoint.
    """
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)