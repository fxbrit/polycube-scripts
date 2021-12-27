# polycube-scripts
scripts to create setups using linux namespaces and [polycube](https://polycube.readthedocs.io/en/latest/intro.html).

## router-nat

<img src="./setups/router-nat.png" alt="router-nat" width="500"/>

## load-balancing-dsr

<img src="./setups/load-balancing-dsr.png" alt="load-balancing-dsr" width="500"/>

## ddos

<img src="./setups/ddos.png" alt="ddos" width="500"/>

to simulate a SYN flood:
```
sudo ip netns exec ns2 hping3p -d 120 -S -w 64 -p 1500 --flood --rand-source-pool 10.11.11.x 10.10.8.1
```