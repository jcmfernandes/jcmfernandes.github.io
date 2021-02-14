---
layout: post
title: small open source contributions
---

Ruby 3 brought us exciting new ways of boosting concurrent execution. While the `Ractor` is enjoying most of the spotlight, I'm personally more excited about `Fiber.set_scheduler`. I'm not going to spend time explaining when [Samuel Williams](https://twitter.com/ioquatix), who introduced it, delivered [a great talk](https://www.youtube.com/watch?v=Y29SSOS4UOc) about it during the 2020' RubyKaigi (virtual) conference.

As I was learning about Ruby's new `Fiber` scheduler, I came across [`nio4r`](https://github.com/socketry/nio4r). This gem provides a cross-platform stateful I/O selector API for Ruby. It's at the heart of projects such as [`puma`](https://github.com/puma/puma) and [`actioncable`](https://github.com/rails/rails/tree/main/actioncable). Internally, it uses the system's asynchronous I/O primitives.

Modern operating systems provide a multitude of options when it comes to asynchronous I/O APIs, and in Linux land [`io_uring`](https://unixism.net/loti/what_is_io_uring.html) is the newest kid on the block. Synthetic benchmarks show very [promising results](https://thenewstack.io/how-io_uring-and-ebpf-will-revolutionize-programming-in-linux/). `nio4r` actually uses [`libev`](http://software.schmorp.de/pkg/libev.html) underneath which only recently - as of version 4.33 - started shipping with (experimental) support for `io_uring`. I noticed that `nio4r` didn't yet include support for `io_uring` so [I went ahead and added it](https://github.com/socketry/nio4r/pull/256) by upgrading its `libev` distribution. Following `libev`'s implementation, it's marked as experimental and it will never be automatically selected as the best backend available on the system. We will hopefully get there soon.

I then noticed that `puma` didn't provide any way of specifying the desired I/O selector backend, and so again [I went ahead added it](https://github.com/puma/puma/pull/2522).

Small improvements that were fun to work on!
