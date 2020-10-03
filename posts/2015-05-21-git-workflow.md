---
title: A good Git workflow or how to correctly rebase your PR
author: Kevin
---

[Git](https://git-scm.com) is **the** tool when it comes to collaborative work.
[GitHub](https://github.com) with its nice UI and its mechanism of _forking_
and _pull requests_ can boost a team's productivity even more. Unfortunately,
there isn't just one way to get things done with Git and GitHub. Here I present
an approach to working with pull requests that has proven to cause little
friction if done correctly. 

The essence of this post is summarised in an [asciinema](https://asciinema.org)
screen cast. If you want some more detail or just prefer reading, continue
below the video.

<script type="text/javascript" src="https://asciinema.org/a/20373.js" id="asciicast-20373" async></script>


## The Setup

For the sake of the exercise, let us say that Alice has started a project and
put it on GitHub. Bob wants to contribute while not getting in Alice's way. We
can emulate GitHub repositories locally by creating a _bare_ repository for
Alice.

<figure>
  <img src="/images/git-workflow-repos.png" alt="Layout of the repositories.">
  <figcaption>This is how the different repositories relate to each other.<figcaption>
</figure>

```bash
git init --bare gh-alice
```

Alice then clones her own repo and adds some content

```bash
git clone gh-alice alice
cd alice
echo 'Hello, world!' > README
git add README
git commit -m 'Add readme.'
git push -u origin master
cd ..
```

Enter Bob. We emulate the _fork_ functionality of GitHub by making a copy of
the “remote” repository and cloning it into a “local” repository that Bob can
work with. We also define Alice's remote repository as a remote resource for
Bob's repository.

```bash
cp -r gh-alice gh-bob
git clone gh-bob bob
cd bob
git remote add alice ../gh-alice
cd ..
```


## Ideally

In a perfect world, Bob makes his changes locally and rebases his local
repository onto Alice's remote repository _before pushing_ to his remote
repository. Let's say, Alice has made the following change:

```bash
cd alice
echo 'Hello, Bob!' >> README
git add README
git commit -m 'Hello from Alice.'
git push
cd ..
```

In parallel, Bob makes a similar change

```bash
cd bob
echo 'Hello, Alice!' >> README
git add README
git commit -m 'Hello from Bob.'
```

Before pushing his changes he fetches the current status of Alice's remote
repository and rebases his branch onto hers.

```bash
git fetch alice
git rebase alice/master
```

Git will then complain about a merge conflict. The important thing here is that
it is now Bob's responsible to fix the conflict and not burden Alice with it.
He proceeds as follows:

```bash
vi README  # Make sure problem is resolved
git add README
git rebase --continue
git push
```

Et voilà, his remote repository has a clean history that Alice can merge
fast-forward style. On GitHub, Bob would create a pull request and Alice would
merge it with one click of a button. In our example, we emulate this by doing

```bash
cd ../alice
git remote add bob ../gh-bob
git fetch bob
git merge bob/master
git push
cd ..
```

Look ma, no errors! Awesome!


## Realistically

Unfortunately, we don't live in an ideal world. In fact, most of the time we
will work with more than two people in parallel and they will contribute in a
much more chaotic fashion than in this somewhat contrived example.

What happens if Bob commits his changes without rebasing before? Or maybe he
did rebase but Alice made some changes before integrating his commits. In both
cases we are left with the problem that bob has to rebase his remote
repository. The following commands emulate this

```bash
cd bob
echo 'My name is Bob.' >> README
git add README
git commit -m 'Bob.'
git push  # looks legal because nothing changed on Alice's branch
cd ../alice
echo 'My name is Alice.' >> README
git add README
git commit -m 'Alice.'
git push
cd ..
```

Now Bob creates another pull requests but Alice tells him that she can't merge
it automatically. He goes back to his local repository and rebases again

```bash
cd bob
git fetch alice
git rebase alice/master
# fix merge conflict etc…
git push
```

But now Git tells him that he can't push because his branch is behind
`origin/master`. What happened is that when he integrated Alice's commit, the
hash of his commit changed and Git doesn't recognise that there are two commits
with different hashes that contain the same changes. At this point he could
pull from his remote again (using `--rebase` to avoid creating another commit
for the merge conflict) and resolve the same merge conflict again. Finally git
will allow him to push again but his history will contain duplicate commits. :(

There is, however, another way. Though discouraged in every other scenario,
`git push -f` is the only way forward in this case. This effectively overrides
the history of the remote repository and should therefore be handled with
_extreme care_.

Once Bob has _ensured that he is in the right folder and on the right branch_
he proceeds to type

```bash
git push -f
```

And Alice once again sees a nice and clean pull request that can be merged
automatically.


## Acknowledgements

[Tim](https://betatim.github.io/) made me realise that I had a wrong impression
when I thought that I could somehow rebase my pull request without using `git
push -f`. He inspired me to look into this in detail and produce this post.


## Questions, Comments, …

As usual, if you have questions or if I got something wrong, [go to the
corresponding issue on GitHub, in order to discuss this
article.](https://github.com/kdungs/dun.gs/issues/6)
