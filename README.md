# ipbench2.buildroot

This repository contains a [Buildroot](https://buildroot.org) package for [ipbench2](https://github.com/au-ts/ipbench/tree/main/ipbench2). This will allow cross-compiling ipbench2 alongside an arbitrary Linux target.

## Usage

In order to use this package, it must be simlinked into `/path/to/buildroot/package/` and an entry must be added to `/path/to/buildroot/package/Config.in` declaring it to the Buildroot configurator. Here is an example Config.in excerpt, placed in the `Networking Applications` section:

```
menu "Networking applications"
    # (place anywhere in this section)
	source "package/ipbench2/Config.in"
```

Note: the `menu` the ipbench2 definition is placed in only affects where it is placed in the Buildroot `menuconfig`.
