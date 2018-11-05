Base Container Centos7
=========================


## Init

```
ctl init --img images:centos/7/amd64
lxc list
ctl start
```

## Container to Image.
```
ctl toimg
```


## Exec bash in container.
```
ctl bash
```

## ssh
```
ctl ssh
```

## portfowward
```
ctl add_pfd --portforward tcp:8888:80
ctl remove_pfd --portforward tcp:8888:80
```
