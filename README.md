# Introduction

If like me you have a favourite Linux distribution (*e.g.* Arch) you could find it a pity to have to install a specific distribution, you are not familiar with, just to be able to set-up a *tellicast* reception system.

Eumetsat pretends that is is possible to set-up a virtual environment (vmware) but without any further clue.

Here are the results of my attempt to do it under a docker container in order to have a lightweight solution. 

It produces an relatively small image 

```
REPOSITORY            TAG       IMAGE ID       CREATED         SIZE  
tellicast-tellicast   latest    3ce6336e48dd   4 minutes ago   263MB  
```

which is built in almost no time (a couple of minutes) and is reproducible on any modern new installation in case of hardware crash..

# Quick installation

Minimal requirements, for the host: `docker` and `wget`.

Eumecast hardware requirements remain valid.

In order to run Eumetsat's *tellicast* in a docker container, please fill an `.env` file containing pertinent information to build and run. An example file (`env.model`) is provided and can be copied and customised.
You need to change at minimum: **LICENSE_USER**, **LICENSE_KEY**, and **NET_IF**.

**LICENSE_USER** and **LICENSE_KEY** must contain the values provided by Eumetsat with you e-token.
**NET_IF** is the interface on which data are multi-cast (use `ip a s` to find which one).

Now run `./tellicast.sh build` to build the environment. This process will download appropriate packages from Eumetsat.
And then `./tellicast.sh start` to launch the docker compose service.

Service should restart automatically after a reboot if docker is properly configured.

If you filled the proper fields and answered correctly to the questions you should be up and running.
By default data will be stored in the `data/` folder (or sub folders) and logs will reside in the `logs/` folder. This could be changed (see [Customisation](#customisation) for further details).

If anything goes wrong, verify that you can access the key using:

```docker compose exec tellicast tc-cast-client -k```

which should gives you the keys used and finish by something like:

```host_key_4 = ****-****-****-**** (Aladdin EToken PRO)```

If not, there is a problem with the key or the communication with it. Check that the key is plugged and exists on your system using `lsusb`.

If no data are received, check that the network interface (**NET_IF**) is the correct one, otherwise multi-cast could not be transferred to the container.

## Customisation

Note that the running user name and group must exist on the host computer.
if not customise the **USER_ID**, **GROUP_ID**, **USER_NAME**, **GROUP_NAME** to suit your needs into your `.env` file.

Reception customisation can be performed by modifying the `etc/*.ini` files. Note that if you rebuild the setup they will be overwritten. To make changes permanent (*e.g.* to store data in different directories for any channel), copy `etc/default/` into `etc/custom/` and modify the files within it.

This set-up has been built and verified under Archlinux (which is far from being the most user friendly to work with)
and which does not accept native *tellicast* setup.

# Detailed description

<mark>TBD</mark>

# Next ?

Any comments are always welcome.
