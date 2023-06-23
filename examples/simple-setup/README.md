# Notes

Try a demo deployment:
```bash
cp kubeconfig.yaml ~/.kube/config
```

Deploy the example:
```bash
k apply -f load_example.yaml
```

Delete the example:
```bash
k delete -f load_example.yaml
```