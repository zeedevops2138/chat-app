ubuntu@DESKTOP-ME24UKS:~/chatapp/ArgoCD$ cat argocd-setup.txt
✅ 1. Pre-requisites
Make sure your KIND cluster is running and kubectl is correctly configured:

kubectl cluster-info --context kind-your-cluster-name

✅ 2. Install ArgoCD into argocd namespace

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

This deploys ArgoCD’s components (API server, controller, repo-server, UI, etc.)

✅ 3. Expose ArgoCD UI via NodePort
By default, ArgoCD API Server is a ClusterIP service. You’ll want to patch it to NodePort so it can be accessed outside the cluster.

kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort"}}'

Now find out which port is assigned:

kubectl get svc argocd-server -n argocd

You’ll see something like:

argocd-server   NodePort   10.96.0.123   <none>   443:31754/TCP   ...

Here, 31754 is the NodePort you can access.

✅ 4. (Optional) Fix NodePort Port to a Known Port
If you want to fix it to a specific port like 32000, patch like this:

kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 32000}]}}'

Then in your KIND config, add this port to extraPortMappings:

extraPortMappings:
  - containerPort: 32000
    hostPort: 32000
    protocol: TCP

(You’d need to recreate the cluster if changing the KIND config.)

✅ 5. Access ArgoCD Web UI
Open in browser:

https://localhost:32000
(or use your actual VM/WSL IP if outside localhost)

✅ 6. Login to ArgoCD

Default username: admin
Default password: initially it’s the pod name of argocd-server.

Get it with:

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

Then login via CLI:

argocd login localhost:32000 --username admin --password YOUR_PASSWORD --insecure

