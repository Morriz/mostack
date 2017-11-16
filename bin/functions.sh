kpk() { ps aux|grep "$@" | awk '{print $2}' | tail -1 | xargs kill; }

#h() { helm template "$@" | k apply -f -; }
#hsk() { helm template --namespace kube-system "$@" | ksk apply -f -; }
#hs() { helm template --namespace system "$@" | ks apply -f -; }
#hm() { helm template --namespace monitoring "$@" | km apply -f -; }
#hl() { helm template --namespace logging "$@" | kl apply -f -; }

hsk() { hi --namespace=kube-system "$@"; }
hs() { hi --namespace=system "$@"; }
hm() { hi --namespace=monitoring "$@"; }
hl() { hi --namespace=logging "$@"; }
htf() { hi --namespace=team-frontend "$@"; }
