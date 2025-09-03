# kubernetes-dashboard

## Accessing the Dashboard UI

```bash
kubectl get secret kubernetes-dashboard-viewer-token -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```
