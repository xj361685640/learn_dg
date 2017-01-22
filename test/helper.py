import numpy as np
from scipy.integrate import quadrature

def coefs(N):
    A = np.vander(np.linspace(-1,1,N), increasing=True)
    B = np.eye(N)
    return np.linalg.solve(A, B)

def polys(N):
    def poly(ii, N):
        alpha = coefs(N)
        return np.poly1d(alpha.T[ii][::-1])

    p = []
    for i in range(N):
        p.append(poly(i, N))
    return p


def polyders(N):
    def polyder(ii, N):
        alpha = coefs(N)
        p = np.poly1d(alpha.T[ii][::-1])
        return np.polyder(p)

    p = []
    for i in range(N):
        p.append(polyder(i, N))
    return p

def getXorJ(coords, dx):
    N = len(coords)
    def XorJ(s):
        y = 0
        if dx == 0:
            p = polys(N)
        elif dx == 1:
            p = polyders(N)

        for ii in range(N):
            y += p[ii](s)*coords[ii]
        return y
    return XorJ

def getIe(coords):
    N = len(coords)
    X = getXorJ(coords, 0)
    J = getXorJ(coords, 1)
    p0 = polys(N)
    p1 = polyders(N)

    Ie = np.empty((N, N))
    for ii in range(N):
        for jj in range(N):
            fun1 = lambda s : p1[ii](s)/J(s)
            fun2 = lambda s : p1[jj](s)/J(s)
            fun  = lambda s : fun1(s)*fun2(s)*J(s)
            Ie[ii, jj] = quadrature(fun, -1, 1)[0]

    return Ie