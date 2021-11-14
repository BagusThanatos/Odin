package net

import win "core:sys/windows"


// Returns an address for each interface that can be bound to.
get_network_interfaces :: proc() -> []Address {
	// TODO
	return nil
}

@private
to_socket_address :: proc(family: Socket_IP_Family, addr: Address, port: int) -> (sockaddr: union{win.sockaddr_in, win.sockaddr_in6}, addrsize: i32) {
	switch a in addr {
	case Ipv4_Address:
		return win.sockaddr_in {
			sin_port = u16be(win.USHORT(port)),
			sin_addr = transmute(win.in_addr) a,
			sin_family = u16(family),
		}, size_of(win.sockaddr_in)
	case Ipv6_Address:
		return win.sockaddr_in6 {
			sin6_port = u16be(win.USHORT(port)),
			sin6_addr = transmute(win.in6_addr) a,
			sin6_family = u16(family),
		}, size_of(win.sockaddr_in6)
	}
	unreachable()
}

@private
to_canonical_endpoint :: proc(native_addr: ^win.SOCKADDR, auto_cast addr_size: int) -> (ep: Endpoint) {
	switch addr_size {
	case size_of(win.sockaddr_in):
		addr := cast(^win.sockaddr_in) native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			addr = Ipv4_Address(transmute([4]byte) addr.sin_addr),
			port = port,
		}
	case size_of(win.sockaddr_in6):
		addr := cast(^win.sockaddr_in6) native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			addr = Ipv6_Address(transmute([8]u16be) addr.sin6_addr),
			port = port,
		}
	case:
		panic("addr_size must be size_of(sockaddr_in) or size_of(sockaddr_in6)")
	}
	return
}