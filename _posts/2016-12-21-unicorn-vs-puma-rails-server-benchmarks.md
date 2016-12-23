---
layout: post
title: "Unicorn vs Puma: Rails server benchmarks"
author: "Tommaso Pavese"
excerpt: >
    As part of a post on web concurrency in Rails, I've been running benchmarks to compare the Puma and Unicorn Ruby HTTP servers. Puma performs better than Unicorn in all tests that were either heavily IO-bound or that interleaved IO and CPU work. In the CPU-bound tests where Unicorn performed better than Puma, the gap was small enough that Puma can still be considered a very good choice.

---

I am writing a post on web concurrency and what it means in Rails, and as part of the research for that article I wrote a benchmark test to compare Unicorn and Puma, the two most widely used Ruby HTTP servers.

Cramming the results at the bottom of that other post doesn't seem right though, as I would prefer to give them the appropriate space, so I have extracted them into this post to give them the space they deserve. I hope you'll find them useful.

The ~~SEO friendly~~ shamelessly click-bait title of this post is quite appropriate: this is yet another benchmark of HTTP servers for Ruby on Rails. This one is a bit more specific than the ones you can find in the first page of Google results, though, because it focusses on CPU and IO--bound workloads and how they affect the performance of the two servers.

Below are the details of [how the benchmarks were set up](#benchmark-setup), the [various benchmarks used](#the-target-endpoints), some [notes on garbage collection](#a-note-on-memory-usage-and-garbage-collection), the [results](#the-results) and the [limitations of these tests](#benchmark-limitations) - if you like, you can skip to [my conclusions](#conclusions).

## Benchmark setup

The benchmark suite [is available on GitHub](https://github.com/tompave/rails_server_benchmark). The repository consists of a Rails `5.0.0.1` application running on Ruby MRI `2.3.3`, against which the benchmarks will run. The application has been configured to run with both Unicorn `5.2.0` and Puma `3.6.2`. All versions are the latest as I'm writing this.

The repository also includes a [script](https://github.com/tompave/rails_server_benchmark/blob/master/script/benchmark.rb) to run the benchmarks and save the results in an output file. It is meant to be executed with the Rails server running in production mode on `127.0.0.1:3000`, at least once for each Rails setup under test. The script iterates through all the target endpoints with increasing concurrency levels, and tries its best to pause between CPU intensive tests to let the machine cool down. It runs the tests with variations of this [ab](http://httpd.apache.org/docs/2.4/programs/ab.html) command:

```
ab -r -c 40 -t 30 http://127.0.0.1:3000/template-render
```

Once all output files are created and properly renamed, [another script](https://github.com/tompave/rails_server_benchmark/blob/master/script/organize.rb) will parse them and aggregate the data in a way that makes it easier to analyze it (ie. so that it's ready to generate charts from the spreadsheet).

The application uses the default production configuration, doesn't interact with the DB (it defaults to SQLite and the pool size has been increased, just in case), and the rendered templates do not link to any assets (which have nonetheless been precompiled to generate the manifest file).

The application comes with config files for both [Unicorn](https://github.com/tompave/rails_server_benchmark/blob/master/config/unicorn.rb) and [Puma](https://github.com/tompave/rails_server_benchmark/blob/master/config/puma.rb), and the Rails server can be started with variations of these commands:

```
RAILS_ENV=production WORKER_COUNT=4 bin/unicorn -c config/unicorn.rb -E production
RAILS_ENV=production WORKER_COUNT=4 THREADS_COUNT=5 bin/puma -C config/puma.rb -e production
```

## The target endpoints

The application implements [a few simple actions](https://github.com/tompave/rails_server_benchmark/blob/master/app/controllers/benchmarks_controller.rb) intended to test specific types of work.

* `GET /fibonacci/:number` calculates a Fibonacci number and responds with the time taken. This is meant to be heavy CPU work. In all tests, targeting this endpoint maxed out the CPU usage of the servers being hit (of course, with one concurrent request only one server does any work at a time).
* `GET /template-render` starts by generating an array of hashes. Then it renders a view template with a ERB loop, conditionals and interpolation. It responds with the rendered HTML. This, as well, is a CPU intensive task.
* `GET /pause/:seconds` sleeps for a few seconds, then responds with the number of seconds in the body. This endpoint is meant to simulate IO-heavy requests with consistent IO waiting times, in order to benchmark how the servers scale when doing mainly IO-bound work.
* `GET /pause-and-render/:seconds` this mixes the previous one with `/template-render`, and is supposed to simulate requests that mix IO and CPU work.
* `GET /network-io` executes an HTTP GET to the Facebook homepage (I guess they can handle it), then responds with the time taken. This too is meant to benchmark how the servers scale when serving heavily IO-bound requests. Benchmarking with network IO hitting a live website is not ideal, however, because we're subject to network inconsistencies out of our control.
* `GET /network-io-and-render` executes the same HTTP request of the previous endpoint, but then it uses the retrieved HTML as data source to render the same template from `/template-render`. This too is meant to be a combination of IO and CPU work.


## A note on memory usage and garbage collection

We can't compare Unicorns and Pumas without spending a few words on memory usage and Garbage Collection. [Here](http://www.schneems.com/2015/05/11/how-ruby-uses-memory.html), [here](https://samsaffron.com/archive/2013/11/22/demystifying-the-ruby-gc) and [here](https://engineering.heroku.com/blogs/2015-02-04-incremental-gc/) you can find a few good primers with examples.

The TL;DR is that memory in Ruby is automatically managed and the Garbage Collector will take care of deallocating objects that are not referenced anymore. Over time Ruby's GC has evolved to include lazy sweeping, bitmap marking, generational and incremental algorithms. It is still a "stop the world" GC however, and it can happen at any time during execution.

The frequency of the GC pauses in the VM depends on the current available memory, which indirectly depends on how many objects are allocated. In Rails applications, responding to web requests is the main unit of work, and that's where most short-lived objects are created and then quickly dereferenced. Regardless of the type and work of the request (i.e. the developer's code), the simple act of receiving and processing a request will cause the framework to allocate objects. This is important enough a metric that people have been measuring how average object allocations changed with each new release of Rails.

Since Puma can handle concurrent requests in the same VM, and since the base object allocation "tax" is the same per requests, Puma will allocate more objects than Unicorn in the same time interval. This will cause the GC to kick in more often. A proof of this is that Puma workers use more memory than Unicorn workers, but that is clearly not a surprise given that they do more work.

Having the GC kick in while your server is serving a request is bad because it will pause VM execution (this was worse with MRI < 2.2). To mitigate this problem, techniques like [Out-of-Band GC](http://tmm1.net/ruby21-oobgc/) have been used over the years: OOBGC consists in manually running the GC _between_ requests to prevent it from running on a random basis _during_ a request. This technique can be used on process-based servers like Unicorn (as GitHub [is currently doing](https://blog.heroku.com/ruby-3-by-3/)) because each process will handle requests sequentially, but it's not so simple to use it with a threaded-based server [like Puma](https://github.com/puma/puma/issues/450) that handles requests concurrently.

In my benchmarks, the memory footprint of Unicorn workers would average to 110 MB, while the Pumas' would grow to around 180 MB.


## The results

The results are available in [ods](/attachments/posts/unicorn-vs-puma-rails-server-benchmarks/Ruby server benchmarks.ods), [xlsx](/attachments/posts/unicorn-vs-puma-rails-server-benchmarks/Ruby server benchmarks.xlsx) and [pdf](/attachments/posts/unicorn-vs-puma-rails-server-benchmarks/Ruby server benchmarks.pdf) formats. They’ve been collected running the benchmarks on a late 2012 27'' iMac (iMac13,2), Intel Core i7 3.4 GHz (4 cores) with 24GB of RAM. The benchmark runner was executed on the same machine.

I benchmarked different configurations of Unicorn and Puma for a total of six  different server setups.

I've run Unicorn with one worker per CPU core (x4) and then with two workers per core (x8). With or without [Hyper-threading](https://en.wikipedia.org/wiki/Hyper-threading), running extra Unicorns helps with IO-bound tasks.  
Puma was tested with four different setups, varying the number of workers and threads per worker: x4:5, x4:10, x8:5 and x8:10 (where "x4:5" means "four workers with five threads each").

Well then, let's have a look.

### Calculating a Fibonacci number

This is by far the most CPU intensive task of the suite.

In the req/s chart you can see that all servers and configurations perform at the same level with one concurrent request, and then immediately align to their top capabilities as soon as we increase the number of concurrent requests.

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/fib_reqs.svg)
</figure>

The first chart clearly shows that, regardless of server implementation, concurrency model and configuration, there is a hard cap to how much processing power can be squeezed out of the CPU. This predictable horizontal trend in req/s is matched by a linear growth in average response time, below:

<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/fib_rt.svg)
</figure>

We can see that even though the machine had 4 cores, configurations running 8 processes perform better than the ones running a single worker per core.

Hyper-threading is definitely a factor. In my tests, 4 processes would use 98-103% CPU each, for a total of ~50% overall system CPU usage. Running 8 processes would max the total usage to ~100%. The performance improvement is not a 2x increase because Hyper-threading is "just" about exposing to the OS each physical core as two logical ones: it's about more efficient scheduling and use of resources, not magic.  

My interpretation is that Puma x8:5 (40 threads in 8 processes) performs better than Puma x4:10 (40 threads in 4 processes) because scheduling in the OS is more efficient and has less overhead than preemptive thread scheduling and context switching in the VM.

In a similar way, Unicorn x8 performs better than the x4 configuration because of better scheduling at the OS level and because running more processes allows them to get a bit more CPU oomph. More processes give us more concurrency in general, but the machine these tests were run on only had 4 cores, so in this case it plays a marginal role.

In both cases (x4 and x8), Unicorn has a barely noticeable performance edge over Puma, and this is probably caused by not having to deal with thread scheduling and context switching. Less frequent GC might also play a role, but the effect here is minimal.


### Rendering a non-simple template

This is the second CPU intensive test. The execution time is shorter than in the previous endpoint, and in fact we can see a higher throughput but similar performance trends.

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/render_reqs.svg)
</figure>

With a stream of sequential requests (C=1), Pumas respond faster than the Unicorns. As the concurrency level increases, Unicorn takes the lead.

<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/render_rt.svg)
</figure>

The distance between the Unicorns and the Pumas here is more pronounced than with the Fibonacci test. The main difference is that, because of the higher throughput, the servers are _moving to the next request_ more frequently.

One possible explanation for the difference in performance is that the GC is running more often in Puma than in Unicorn (comments with corrections are welcome). This because the expensive resource allocation phase of Rails' request handling is happening more often, but also because ERB template rendering requires to create a few large strings that will take quite a bit of memory. This is an element that we didn't have to deal with in the previous test.

Another factor could be that now in Puma the thread scheduler has to context switch more frequently, and this too could have an impact. In support of this claim there is the fact that not only is the distance between Unicorns and Pumas greater, but also is the difference between Puma x8 and Puma x4: with the workload spread more evenly across a larger number of processes, each VM's scheduler has less work to do.

Or maybe Unicorn is just better than Puma at this kind of work.



### Sleeping for 2 seconds

This test simulates requests with constant time IO work and as little CPU work as possible. As expected, Puma completely outperforms Unicorn.

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/sleep_reqs.svg)
</figure>
<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/sleep_rt.svg)
</figure>

Here each Unicorn process will move from request to request, with each taking ~2s. A Puma process with 10 threads, on the other hand, can accept 10 requests with little effort as they will all just wait idle.

As long as it has available threads to process the incoming requests, Puma performs well and the response time stays close to 2000ms, growing slightly when the number of threads is close to be saturated. Exceeded that limit, Puma's performance decreases at the same pace of Unicorn's.

The average response time of Unicorn x4 grows so high in the second chart that it's difficult to see the performance details of the Pumas, but [the numbers](Ruby server benchmarks.pdf) look very good.

Interestingly, for this kind of workload running fewer Puma processes with more threads is better: Puma x4:10 has a clear edge over Puma x8:5.


### Sleeping for 2 seconds + Rendering

We've looked at how the servers behave with CPU-bound and IO-bound workloads. What happens if we mix them? Interleaving CPU work with IO waiting times is an important test because that's what most Rails applications actually do.

The implementation for this endpoint combines the "render template" test with the sleep time of the previous one. It starts by preparing the same data to be rendered, than sleeps for 2 seconds, and terminates by rendering the templates.

The performance trends are almost identical to the "sleep" test, but the throughput is a bit lower:

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/sleep_render_reqs.svg)
</figure>
<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/sleep_render_rt.svg)
</figure>

A lower throughput is to be expected, since here we're doing more CPU work. And yet, it looks like the IO component has a higher effect than the CPU one, or perhaps a 2s pause is long enough to make the time spent rendering the template irrelevant (the last benchmark will test something similar with shorter IO times).

The main difference between Unicorns and Pumas here is that while each Unicorn has no option but execute everything sequentially, a Puma worker can render the template on a thread while the other ones are in the sleep phase. This is a huge advantage.



### Network IO

This test is very similar to the "sleep for 2 seconds" one, but it executes a real IO activity in the form of an HTTP request. As already mentioned this kind of test is not ideal because there are too many external factors, but it's still interesting to see how the two servers cope with this kind of situation.

Compared to the "sleep" test, the IO task is faster: ~600ms Vs 2000ms.

As expected, the throughput is much higher but the trends are largely the same.   

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/network_reqs.svg)
</figure>
<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/network_rt.svg)
</figure>

As you can see, Unicorn x4 performed very poorly in the C=10 test. This was caused by some network issues during that benchmark.

I considered running it again, but I decided not to for two reasons. First off, that value is so off that it's obviously an anomaly, and it's still easy to distinguish the overall trend. Secondly, it's a clear example of what happens on a low-concurrency server when some problem blocks a request. Not _all_ requests in that test were slow, just a fraction. Still, those requests blocked all the available workers and caused a congestion with cascading effects, so that all subsequent requests were affected.


Also interesting that Puma x4:10 keeps performing better than Puma x8:5. With IO-bound work, fewer Puma processes with more threads seem to be a better alternative.


### Network IO + Rendering

This is the network IO version of the "sleep + render" test. Same considerations apply.

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/network_render_reqs.svg)
</figure>
<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the number of concurrent requests (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/network_render_rt.svg)
</figure>

What's different in this case is that, since the network IO units of work complete faster than the constant `sleep(2)` pauses, the template rendering work (CPU) is executed more often.

And we can see this in action, as Puma x8:5 performs closer to Puma x4:10 than it did in the "sleep + render" benchmark. As we have already observed, x8:5 is better when executing CPU-intense tasks and x4:10 is better at dealing with IO. Here the workload is again mixed, but the CPU component is heavier than it was in the "sleep + render" test.

Another thing we can observe is that the average response time growth, while still exponential, is a bit _flatter_ than in the two "sleep" benchmarks. At the same time, the req/s data for the Unicorns quickly becomes horizontal. This, too, could be an effect we’ve already seen: Unicorn quickly reaches its peak performance with CPU work, but maintains that level well.

### Tuning Puma

Puma has been consistenly outperforming Unicorn in all IO tests and mixed IO-CPU tests, and in the fibonacci and render tests the distance from Unicorn was quite small.

Let's look at the data from a different angle, to compare how the configurations of Puma performed. For this, I am going to limit the data set to the results of the tests executing 50 concurrent requests.

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the diffferent Puma configurations (horizontal axis), the different data series represent the performance on the different test endpoints.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/pumas_endpoints_reqs.svg)
</figure>
<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the diffferent Puma configurations (horizontal axis), the different data series represent the performance on the different test endpoints.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/pumas_endpoints_rt.svg)
</figure>

These two charts plot the performance on the test endpoints for the different configurations of Puma on the horizontal axis. The difference between thw two central values (x4:10 and x8:5) is interesting because it shows what happens when the same number of threads in distributed in a different number of OS processes.

It's also interesting to rotate the charts, to compare the Pumas side-by-side on each test endpoint. The output is a summary of the other charts we have already seen.

<figure>
![A chart plotting the average requests per seconds (vertical axis) on the different test endpoints (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/endpoints_pumas_reqs.svg)
</figure>
<figure>
![A chart plotting the average response time per request in milliseconds (vertical axis) on the different test endpoints (horizontal axis), the different data series represent the performance of different servers and configurations.](/images/posts/unicorn-vs-puma-rails-server-benchmarks/charts/endpoints_pumas_rt.svg)
</figure>

## Benchmark Limitations

The data presented in this post comes from synthetic benchmarks.  

While I tried in some tests to mix and match CPU and IO work, real world Rails applications deal with a wide spectrum of CPU and IO workload combinations.

For example, most applications will receive traffic for different types of requests at the same time, and it's hard to control what kind of work is executed on which server process. You could do "intelligent" routing by checking the request path in the load balancer, but it's rarely worth the extra complexity and doing so means that single-purpose servers are a point of failure, so it's generally a bad idea.

As a consequence, Rails servers normally deal with various combinations of CPU and IO work, whereas these benchmarks have stressed the application with a single type of workload at a time.

The goal here was to highlight what the two servers are good or bad at under extreme conditions. Before choosing one of the two servers for your application you should benchmark it by hitting its real endpoints. The [benchmarking scripts](https://github.com/tompave/rails_server_benchmark/tree/master/script) I wrote to run these tests can be easily adapted to work with other applications.

## Conclusions


The results clearly show that Puma performs better than Unicorn in all tests that were either heavily IO-bound or that interleaved IO and CPU work. In the CPU-bound tests where Unicorn performed better than Puma, the gap was small enough that Puma can still be considered a very good choice.

The optimal configuration for Puma’s thread and process pools greatly depends on the workload characteristics of the application, and tuning Puma is still something that requires tests and benchmarks.


I hope that this post was helpful, and thanks for reading!


