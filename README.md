1. Datadog Setup

To begin, you'll need a Datadog account. If you don't have one, sign up at Datadog's website. Once logged in, locate your API Key and Application Key:
- `API Key`: Navigate to Organization Settings > API Keys. This key is used by the Datadog Agent to send metrics, logs, and traces to your Datadog account. 
- `Application Key`: Navigate to Organization Settings > Application Keys. This key is used by certain Datadog APIs and client libraries for authentication. While not strictly required for basic ddtrace setup, it's good practice to be aware of its location for more advanced configurations.Keep these keys secure, as they grant access to your Datadog account.

2. Kubernetes Agent InstallationThe Datadog Agent collects metrics, logs, and traces from your Kubernetes cluster and sends them to Datadog. We recommend using Helm for installation, as it's the most robust and recommended method.
Prerequisites:
- `kubectl` installed and configured to connect to your Kubernetes cluster. 
- `helm` installed.

Installation Steps:
1. Add Datadog Helm Repository:

```bash
kubectl create namespace datadog
kubens datadog
helm repo add datadog https://helm.datadoghq.com
helm install datadog-operator datadog/datadog-operator
```

2. Create a Kubernetes Secret for your Datadog API Key:

Replace `<YOUR_DATADOG_API_KEY>` with your actual Datadog API Key.

```bash
kubectl create secret generic datadog-secret --from-literal api-key=<YOUR_DATADOG_API_KEY>
```

3. Install the Datadog Agent using Helm:

Follow instructions in the [Install the Datadog Agent on Kubernetes](https://us5.datadoghq.com/fleet/install-agent/latest?platform=kubernetes) to configure and update the Datadog Agent.
Remember to check `Application Performance Monitoring` and optionally `Log Management` under `Customize your observability coverage` (i.e. Step 3).

datadog.apiKeyExistingSecret: References the Kubernetes Secret holding your Datadog API key.datadog.site: Specifies your Datadog site (e.g., datadoghq.com, eu.datadoghq.com).apm.enabled=true: Enables APM (Application Performance Monitoring) and trace collection.apm.hostPort=8126: Exposes port 8126 on the host, which the ddtrace library uses to send traces to the Agent.Verify Agent Installation:Check if the Datadog Agent pods are running in the datadog namespace:kubectl get pods -n datadog

You should see datadog-agent pods in a Running state.

4. Python Microservices Instrumentation

We'll instrument both the web-api and client-service using ddtrace. The provided GitHub repository (https://github.com/dennis-bilson-port/datadog-svc-dependency-setup-template.git) will serve as our base.
Clone the Repository:git clone https://github.com/dennis-bilson-port/datadog-svc-dependency-setup-template.git
cd datadog-svc-dependency-setup-template

Modifications to requirements.txt:
Add `ddtrace` to the `requirements.txt` file in both web-api and client-service directories.
web-api/requirements.txt:

```txt
fastapi==0.103.1
uvicorn[standard]==0.23.2
ddtrace==1.18.1
requests==2.31.0
```

client-service/requirements.txt:
```txt
fastapi==0.103.1
uvicorn[standard]==0.23.2
ddtrace==1.18.1
requests==2.31.0
```

Instrumentation in main.py (Both Services):
The ddtrace library can automatically instrument many popular libraries and frameworks. 
For FastAPI, the recommended way is to use ddtrace-run when starting your application. 
This automatically patches the necessary components. However, to ensure proper service naming, environment, and version tagging, we'll leverage environment variables.
web-api/main.py
No direct code changes are strictly necessary in main.py if you use ddtrace-run and set environment variables. 
ddtrace will automatically instrument FastAPI and incoming HTTP requests.For outgoing requests (if web-api were to call another service), 
ddtrace would also instrument the requests library automatically.client-service/main.pySimilarly, for client-service, ddtrace will automatically instrument 
FastAPI for incoming requests and the requests library for outgoing HTTP calls to the web-api.Ensure your client-service/main.py makes an HTTP call to the web-api. For example:# client-service/main.py

```python
from fastapi import FastAPI
import requests
import os

app = FastAPI()

WEB_API_URL = os.getenv("WEB_API_URL", "http://localhost:8000") # Default for local testing

@app.get("/")
async def read_root():
    return {"message": "Hello from Client Service!"}

@app.get("/call-api")
async def call_web_api():
    try:
        response = requests.get(f"{WEB_API_URL}/hello")
        response.raise_for_status() # Raise an exception for HTTP errors
        return {"message": "Called Web API", "api_response": response.json()}
    except requests.exceptions.RequestException as e:
        return {"error": f"Failed to call Web API: {e}"}
```

Key ddtrace Environment Variables:
These environment variables are crucial for ddtrace to function correctly and for unified service tagging:
`DD_AGENT_HOST`: The hostname or IP address of the Datadog Agent's trace agent. In Kubernetes, this will typically be the Datadog Agent service name.
`DD_TRACE_AGENT_PORT`: The port on which the trace agent listens to (default is 8126).
`DD_SERVICE`: The name of your service (e.g., web-api, client-service).
`DD_ENV`: The environment (e.g., dev, staging, prod).
`DD_VERSION`: The version of your service (e.g., 1.0.0).
`DD_APM_ENABLED`: Set to true to enable APM.
`DD_TRACE_ENABLED`: Set to true to enable tracing.
These will be passed via Kubernetes Deployment YAMLs.

5. Dockerization

We need to Dockerize both microservices. We'll use multi-stage builds for optimization.

web-api/Dockerfile

```Dockerfile
# Stage 1: Builder
FROM python:3.9-slim-buster AS builder

WORKDIR /app

# Install dependencies
COPY web-api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runner
FROM python:3.9-slim-buster

WORKDIR /app

# Copy only the necessary files from builder
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY web-api/main.py .

# Expose the port FastAPI runs on
EXPOSE 8000

# Command to run the application with ddtrace-run
# DD_AGENT_HOST will be set by Kubernetes environment variables
CMD ["ddtrace-run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

client-service/Dockerfile

```Dockerfile
# Stage 1: Builder
FROM python:3.9-slim-buster AS builder

WORKDIR /app

# Install dependencies
COPY client-service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runner
FROM python:3.9-slim-buster

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY client-service/main.py .

# Expose the port FastAPI runs on
EXPOSE 8001

# Command to run the application with ddtrace-run
# DD_AGENT_HOST will be set by Kubernetes environment variables
CMD ["ddtrace-run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```

Build Docker Images:From the root of your cloned repository:

```bash
docker build -t <docker-username>/web-api:latest -f web-api/Dockerfile .
docker build -t <docker-username>/client-service:latest -f client-service/Dockerfile .
```

If using Minikube, load these images into Minikube's Docker daemon:

```bash
eval $(minikube docker-env)
docker build -t <docker-username>/web-api:latest -f web-api/Dockerfile .
docker build -t <docker-username>/client-service:latest -f client-service/Dockerfile .
eval $(minikube docker-env -u) # Unset Minikube's Docker environment
```

For cloud providers, push these images to a container registry (e.g., Docker Hub, ECR, GCR) and update your Kubernetes manifests with the correct image paths.

6. Kubernetes DeploymentCreate Kubernetes Deployment and Service YAML files for each microservice.kubernetes/web-api-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-api
  namespace: datadog
  labels:
    app: web-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-api
  template:
    metadata:
      labels:
        app: web-api
    spec:
      containers:
        - name: web-api
          image: <docker-username>/web-api:latest
          ports:
            - containerPort: 8000
          env:
            - name: DD_AGENT_HOST
              value: "datadog-agent"
            - name: DD_ENV
              value: "prod"
            - name: DD_SERVICE
              value: "web-api"
            - name: DD_VERSION
              value: "1.0.0"
            - name: DD_LOGS_INJECTION
              value: "true"
            - name: DD_TRACE_ANALYTICS_ENABLED
              value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: web-api
  namespace: datadog
spec:
  type: ClusterIP
  selector:
    app: web-api
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
```

kubernetes/client-service-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client-service
  namespace: datadog
  labels:
    app: client-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: client-service
  template:
    metadata:
      labels:
        app: client-service
    spec:
      containers:
        - name: client-service
          image: qcodelabsllc/client-service:latest
          ports:
            - containerPort: 8001
          env:
            - name: WEB_API_URL
              value: "http://web-api"
            - name: DD_AGENT_HOST
              value: "datadog-agent"
            - name: DD_ENV
              value: "prod"
            - name: DD_SERVICE
              value: "client-service"
            - name: DD_VERSION
              value: "1.0.0"
            - name: DD_LOGS_INJECTION
              value: "true"
            - name: DD_TRACE_ANALYTICS_ENABLED
              value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: client-service
  namespace: datadog
spec:
  type: ClusterIP
  selector:
    app: client-service
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8001
```
Deploy to Kubernetes:From the kubernetes directory:

```bash
kubectl apply -f web-api-deployment.yaml
kubectl apply -f client-service-deployment.yaml
```

Verify that your deployments and services are running:

```bash
kubectl get deployments
kubectl get services
kubectl get pods
```

6. Testing Traces 

Now, let's generate some traffic to see traces in Datadog.
If using Minikube:Port Forward the Client Service:

```bash
kubectl port-forward service/client-service 8001:80
```

This will forward local port 8001 to the client-service pod's port 8001.

Simulate Calls:
Open a new terminal and use curl or Postman to hit the client-service endpoint that calls the web-api:

```bash
curl http://localhost:8001/call-api
```

You should get a JSON response indicating the call to the Web API was successful.
If using a Cloud Provider:
Expose Client Service via LoadBalancer:
Change the type of the client-service Kubernetes Service from ClusterIP to LoadBalancer.

kubernetes/client-service-deployment.yaml (updated service type):

```yaml
# ... (rest of the deployment) ...
---
apiVersion: v1
kind: Service
metadata:
  name: client-service
  namespace: datadog
spec:
  type: LoadBalancer
  selector:
    app: client-service
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8001
```

Apply the updated service:

```bash
kubectl apply -f kubernetes/client-service-deployment.yaml
```

Get LoadBalancer IP/Hostname:It might take a few minutes for the LoadBalancer to provision.

```bash
kubectl get services client-service
```

Look for the EXTERNAL-IP or EXTERNAL-HOSTNAME.Simulate Calls:
Use curl or Postman with the external IP/hostname:

```bash
curl http://<EXTERNAL-IP-OR-HOSTNAME>:8001/call-api
```

Repeat the curl command several times to generate multiple traces.

8. Observing in Datadog

Finally, let's verify that your traces are flowing into Datadog.
- Log in to your Datadog account.
- Navigate to `APM` > `Service Map`:
- In the left-hand navigation, select `Map`.
- You should see your `client-service` and `web-api` as interconnected nodes, indicating that distributed traces are being collected.
- In the left-hand navigation, select `Catalog`. Here you can see individual services. You should be able to find traces originating from `client-service` with spans that include calls to `web-api`. Clicking on a service and then `Relationships` tab will show you the graph, detailing the execution flow and latency between the two services.
- Verify that:
  - Spans for incoming and outgoing HTTP requests are captured.
  - The service.name, env, and version tags are correctly applied to the spans.
  - The trace context is propagated between `client-service` and `web-api`, linking the spans together into a single distributed trace.
This comprehensive setup ensures that your Python microservices in Kubernetes are fully observable with Datadog APM, 
providing valuable insights into their performance and interdependencies.

Images:
- [Service Relationships](./images/relationships.png)
- [Service Map](./images/service-map.png)
