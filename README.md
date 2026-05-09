
## Desloppify

Run the desloppify lint scan explicitly when you want to check the repo:

```bash
make desloppify
```

The target runs `python3 -m desloppify scan --path .` on demand.

`.desloppify/` is ignored so local scan output does not pollute the repo.


