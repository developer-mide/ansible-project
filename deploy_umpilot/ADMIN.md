
## Commands for administrative use

### Sync newer files from the local db/ folder shared location:

`
rsync -rtvi --no-perms --chmod=Fg+r db/ /mnt/share/ansible_db/
`

(add user@server: before the receiving path for pushing to remote)

### Port Forwardings

Via SSH and SOCKS5: add dynamic port forwarding via an ssh session to endudai, e.g. `ssh -D 9999`,
and then configure your applications to use a SOCKS5 proxy on localhost:9999,
preferably  with _remote name resolution_ (to support hostnames provided by endudai/endudai's network)

If that is not possible, individual ports can be forwarded using 'local port forwards', e.g. by adding `ssh -L 10003:192.168.11.126:22` - in this
example, the application could connect to localhost:10003 and then reach the Jetson currently having 192.168.11.126 in endudai's network.

