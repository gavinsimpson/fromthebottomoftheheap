---
title: "File synchronisation with Unison"
status: publish
layout: post
published: true
type: post
tags:
- Sync
- Backup
- Files
active: blog
category: Computing
---

It's becoming a fairly common experience to work on two or more
computing devices; say a desktop/workstation in the office and a
laptop when travelling or a home desktop. Which is great, but how do
you keep all those machines in sync so that you have the latest
versions of your files available no matter where you need to work?

For many years I have worked on three machines

 1. my multi-CPU, multi-core, large-RAM workstation in the office,
 2. a standard desktop at home, and
 3. my trusty laptop.

In addition I also sync data to a portable hard drive, just in case.
Working on multiple machines brings with it a major problem; how to
do  ensure you have the latest versions of your files in all
locations?

I've used a number of solutions (yes, even back to the Microsoft
Briefcase tool in Windows 95!) for this problem, but have settled on
a rather neat little opensource tool called
[Unison](http://www.cis.upenn.edu/~bcpierce/unison/).

<ul class="thumbnails pull-left ftboth-img-right">
<li class="span3">
<div class="thumbnail">
<img src="{{site.url}}/assets/img/posts/unison.gif">
<figcaption>Unison; a multi-OS file synchronisation tool</figcaption>
</div>
</li>
</ul>

Unison is a file synchronisation tool for flavours of Unix (Linux
and OS X included) and Windows. It is designed to keep pairs of
computers in sync by replicating changes made on one of the machines
in the pair to the other and vice versa, at the same time. In
multi-machine setups, like mine, you don't have a single pair of
machines to keep in sync, but many pairs. In that situation you need
to assign one computer as the hub or master machine with which all
the others are synchronised. For me, the master is my Linux
workstation in the office and I sync the other two computers with it.

Unison connects pairs of machines either via a socket or over SSH.
To keep network usage to a minimum, Unison uses an rsync-like
algorithm to transfer  over the network only the parts of files that
have changed, reconstituting the file at the other end from the bits
that didn't change and the transfered bits that did. It's all rather
neat and I keep my `work` folder which contains all my work since
about 2002 (plus some earlier things) in sync over my cable/DSL
connection at home, despite it being about 25GB in size!

On Linux, Unison is pretty easy to install as it tends to be
available through your distro's package manager (`yum` in my case on
Fedora/RHEL/Centos). It's a little trickier to install on other
OSes, but mainly because you need an SSH client on each machine you
want to sync, and an SSH server daemon running on the hub (master)
machine. On Linux, those things come as standard or are easily added
via the package manager. It isn't quite so easy to set those things
up if all you have are Windows boxes you need to sync too, but still
doable. Also note that the file formats used in replicating data
between machines has changed a in recent versions of Unison, so be
careful to install the same version on all your machines.

Obviously you also need to have a machine that you can connect to
via SSH and which will act as the hub or master machine. This will
not in general be a computer you have sitting on your home network
behind your cable/DSL router. I use my Linux workstation in the
office as my master node.

If you just want to sync to an external hard drive, you don't need any
of the above; just point it to the source folder on your machine and
the folder to sync to on the external drive and it will handle the
rest, just as if you were syncing data between two folders on the hard
drive of a single computer.

Once you have Unison installed on all the machines you wish to sync,
you need to add a *profile*. A profile is how a particular
replication pair is defined and configured. You configure the
profile on each of the "slave" nodes you wish to sync with the
master. In my setup, I created the same profiles on both my home PC
and my laptop to sync their `~/work` folders with `~/work` on the
master, my workstation in the office.

Handily in recent versions of Unison configuring this is done
through a wizard, where you provide a name and description for the
profile and then choose the type of connection:

 * *Local* if you want to sync to another folder on the same machine
 or an external drive (make sure the external drive is connected),
 * *SSH* if you want to sync over a network or the internet.

There are two other options, but connecting using RSH is not secure
and connecting via a plain TCP connection (the fourth option) requires
a little more effort to set up. If you can SSH between machines it is
simplest to use that connection method.

To connect via SSH you need to provide the host name, e.g.
`foo.biol.uregina.ca` and your username on the master machine. I
would check that you can connect to the master via SSH from the
shell/terminal before you provide the required information to Unison
as it will be easier to debug connection problems there than in
Unison. If you are syncing over the internet, make sure the *Enable
compression* option is selected.

Next specify the local and remote folders you wish to sync. This is
the root folder to sync, so everything in this root and below it
(contained within it) in the filesystem will be synced (by default,
though you can instruct Unison to ignore paths later). For the
remote directory, specify the location of your files. For me this is
`/home/USERNAME/work`.

The next option asks if you are syncing a FAT partition. This may be
the case if you are syncing with Windows (although newer versions tend
to use NTFS instead of FAT), and is usually the case for USB keys or
external hard drives.

After that, you're done.

Once you select a profile to synchronise, Unison connects to the
other machine in the pair and consults the replication states for
both machines and then works out what has changed since the last
sync. At the time of the first sync these replication states won't
exist, so it can take quite a while for it to index the files on
both machines and decide what needs to be transferred (though I do
do this with 25GB of data).

Once Unison has worked out what needs to be synced, you'll be presented
with the main Unison interface containing a list of all the paths that
need to be synced.

![Unison's GUI interface in all its
glory]({{site.url}}/assets/img/posts/unison-example-screengrab.png)

The direction of synchronisation (from local to remote or vice
versa) is also indicated. For text files a diff of the changes
between versions on the two machines can be produced. You can
override the direction of synchronisation using the tool bar buttons
or the cursor keys. The menus also allow you to temporarily or
permanently ignore paths in the list, or to set all synchronisation
directions in favour of the remote or the local machine, or to
automatically resolve conflicts in favour of one host or another.
Unison can also try to merge changes made to the same file on both
nodes. Clicking Go or pressing <kbd>g</kbd> will start the
synchronisation job.

Unison can also be started from a shell, where you can specify the
profile to use and other options. It also has a text interface for
use solely within a shell environment, if that's what you prefer,
and has a batch mode if you want to incorporate that into a shell
script or cron job. For example, to run the profile named
**MyProfile** in text mode you'd use

``` {.bash}
unison MyProfile -ui text
```

Personally, I like to be able to scan through the changes indicated,
which I find easier to do with the GUI.

Unison can be configured in a wide variety of ways, by editing the
`.prf` files located in the `~/.unison` folder. To get you started there are
three [example
profiles](http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#profileegs) in the Unison
[manual](http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html), where all the settable preferences (& command line arguments) are listed and explained.

There is a lot more to Unison than I have covered here, including
having Unison make backups of the files it changes, and the ability
to nest profiles so that a large replica can be synced in parts
rather than having to check the entire replica. However, to use
Unison effectively, you don't need to dabble with all the options and
advanced features; I've used it for years without needing to fiddle
in my profiles' `.prf` files.

If you've been wanting a tool to help sync up your work to two or more
computers, give Unison a whirl.
