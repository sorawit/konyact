from brownie import a, KayaProxy, Kaya, KayaCenter, KayaDistributor, KayaEscrow, SoKaya


def main():
    dist_impl = KayaDistributor.deploy({'from': a[0]})
    cent_impl = KayaCenter.deploy({'from': a[0]})
    soky_impl = SoKaya.deploy({'from': a[0]})

    kaya = Kaya.deploy({'from': a[0]})
    dist = KayaProxy.deploy(dist_impl, a[0], dist_impl.initialize.encode_input(kaya), {'from': a[0]})
    cent = KayaProxy.deploy(cent_impl, a[0], cent_impl.initialize.encode_input(kaya, a[0]), {'from': a[0]})
    soky = KayaProxy.deploy(soky_impl, a[0], soky_impl.initialize.encode_input(cent, dist), {'from': a[0]})

    print('Hello, World!')
