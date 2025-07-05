✅ 1. Install the NGINX Ingress Controller Apply the official manifest (replace version if needed):

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/kind/deploy.yaml

Note: v1.10.1 is the latest stable as of July 2025. You can change it if a newer version is available.

⏳ 2. Wait for the Controller to Be Ready Watch the pod status until the ingress-nginx-controller is running:

kubectl get pods -n ingress-nginx

🔧 3. Patch the Service to Use NodePort (Required for KIND) Since KIND doesn’t support LoadBalancer, change the ingress service type:

kubectl patch svc ingress-nginx-controller -n ingress-nginx
-p '{"spec": {"type": "NodePort"}}'

Then confirm the NodePort:

kubectl get svc -n ingress-nginx

Look for ports like 80:xxxxx/TCP — the value after the colon (e.g., 31347) is the NodePort you'll access via localhost.

🏷️ 4. Label the Node (Required by Ingress) Get the node name:

kubectl get nodes

Then label your control plane node to allow ingress to schedule:

kubectl label node ingress-ready=true

For KIND, it’s usually:

kubectl label node kind-control-plane ingress-ready=true
