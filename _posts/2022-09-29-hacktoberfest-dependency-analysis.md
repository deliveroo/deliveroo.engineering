---
layout: post
title: Analysing our dependency trees to determine where we should send Open Source contributions for Hacktoberfest
authors:
  - "Jamie Tanna"
excerpt: >
  How we're using GitHub Advanced Security's dependency scanning
  functionality to determine what our most popular dependencies are, and whether
  we can find any Open Source contributions for the month of Hacktoberfest.
date: 2022-09-29T13:10:23+0100
---
## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Why contributing to Open Source is so important

In recent years, it has become unavoidable to build software on top of Open Source. This is _absolutely_ a great thing, and allows developers to focus on fewer areas of domain specialisation as possible, as well as allowing a much wider range of users to pick up on defects and bring new features to our tools.

However, with events such as the [Log4Shell](https://en.wikipedia.org/wiki/Log4Shell) security vulnerability, times where maintainers have removed their libraries [from package and source repositories](https://www.bleepingcomputer.com/news/security/dev-corrupts-npm-libs-colors-and-faker-breaking-thousands-of-apps/), sometimes in [political protest](https://www.wired.com/story/developer-deletes-code-protest-ice/), it's understandable that businesses are somewhat hesitant about the sustainability of projects.

One of the key things that all Open Source licences highlight is that they're provided "as is", with “no warranty”. Although maintainers may get to that bug fix, or incredibly high severity security fix, the whole point is that the source is available for you, dear reader, to contribute that fix without needing to wait for a maintainer to assist you.

Sometimes it's straightforward to spot an issue and try to fix it yourself, but if you've never contributed to an Open Source project before it can be particularly daunting, especially if it's a considerably large codebase or if it's critical infrastructure for several companies and projects.

Contributing to Open Source is one of those things that's best learned by doing, which is fortunate because in the month of October, DigitalOcean are running an event across the world run called [Hacktoberfest](https://hacktoberfest.com), which aims to be a celebration of Free and Open Source and to give more folks exposure to contributing to projects. I've been participating in Hacktoberfest since 2014, and it has truly changed the way that I engage with Open Source. It has given me the opportunity to be more comfortable engaging in Open Source and, as a maintainer on several large projects myself, it has given me further empathy on both sides of the experience.

### Data-driven dependency analysis

Coming up to Hacktoberfest this year - my first Hacktoberfest since joining Deliveroo - I wanted to spread the love and see if I could give a similar experience to other folks, as well as to try and get us to contribute to some of the projects that power the business.

A few months ago, I [wrote about an idea on my personal blog](https://www.jvt.me/posts/2022/06/01/idea-supply-chain-monetisation/) about programmatically determining how (Open Source) libraries are used and, in that case, contributing financially, but the concept still works for contributing in other ways. I decided that I wanted to use the same dependency analysis approach, using the dependency tracking functionality we have available through GitHub Advanced security. Deliveroo is a data-driven company, so being able to bring some data to teams, to highlight commonly used libraries that may be good candidates for contributions, was really important.

To do this, the overarching steps were:

- get a list of all repositories to scan
- get dependency scanning enabled across all of our repositories, which was scriptable
- grab the list of dependencies for each repository
- extract the dependencies for each repo and insert them into an SQLite database
- run some queries to pull out the most popular direct and transitive dependencies

Across our repositories, it's been especially interesting to see that our most used (direct) dependencies seem to be testing, data serialisation/deserialisation, and frameworks like React and Rails.

Although I can't do the analysis of your own projects for you, I can at least share the scripts I (hackily!) put together to do the work.

The below code is shared under the MIT license.

#### Listing repositories to scan

Before we could start doing anything in the org, we needed to list all of our repositories. I ended up performing a paginated query for the list of repos, using the `gh` CLI:

```sh
for f in {11..30};
gh api "/orgs/deliveroo/repos?per_page=100&page=$f" | jq '.[].name' >> repos.txt
# then some post-processing required to remove any `”`s and make sure the list was sorted and unique, as the result would be in the format:
#   "deliveroo.engineering"
#   "determinator"
```

This could've been improved with the GraphQL endpoint, but as it was a one-time operation, I decided to go for an inefficient route.

#### Enabling dependency scanning across the org

Now I had all the repositories listed, I needed to make sure that we had all repositories opted-in to dependency scanning. After finding the [GitHub docs to enable vulnerability alerts](https://docs.github.com/en/rest/repos/repos#enable-vulnerability-alerts), this was straightforward as we could script it easily, for instance:

```sh
# this is a subset of the 1900(!) repos
for repo in deliveroo.engineering merge-pr-to-branch jsonrest-go determinator; do
  echo "Starting $repo"
  gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/deliveroo/$repo/vulnerability-alerts
done
```

#### Listing the dependency graph

Until I found [Simon Willison's post](https://til.simonwillison.net/github/dependencies-graphql-api) about this, I was getting a bit disheartened that this wasn't possible, but it turns out it was just hidden in a preview API.

While playing around in the GraphQL API docs, I found that this was the best way to get all the packages that a given package has for direct and transitive dependencies.

To script this further I created the file `get.sh`:

```sh
#!/usr/bin/env bash
repo=$1
# could also be a `gh api` call
curl -s https://api.github.com/graphql -X POST \
-H "Authorization: Bearer ..." \
-H "Content-Type: application/json" \
-H 'Accept: application/vnd.github.hawkgirl-preview+json' \
-d "$(jq -c -n --arg query '
{
  repository(owner:"deliveroo", name:"'$repo'") {
    dependencyGraphManifests {
      totalCount
      edges {
        node {
        filename
          dependencies {
            totalCount
            nodes {
              packageName
              packageManager
            }
          }
        }
      }
    }
  }
}
' '{"query":$query}')"  | jq > data/$repo.json
```

#### Converting raw dependency graph into a database

Now I had the raw dependency data, I needed to break it down into a form that we could more easily query. I used `jq` to break this down into a smaller set of JSON objects using the script `filter.sh`:

```sh
#!/usr/bin/env bash
repo="$(basename ${1/.json/})"
jq '[.data.repository.dependencyGraphManifests.edges[].node as $dep | $dep.dependencies.nodes[] | {repo: "'$repo'", packageName: .packageName, packageManager: .packageManager, filename: $dep.filename, repoPath: ("'$repo'/" + $dep.filename)}]' $1
```

#### Tying it all together

Now we have all of the scripts, it was a case of executing them together.

The main script was `do.sh`:

```sh
#!/usr/bin/env bash
[[ ! -f data/"$1.json" ]] && ./get.sh "$1"
# ./get.sh "$1"
./filter.sh data/"$1".json | sqlite-utils insert db.db packages -
```

This was invoked one time per repo:

```sh
for repo in deliveroo.engineering merge-pr-to-branch jsonrest-go determinator; do
  ./do.sh $repo
done
```

This would then insert all the package information into an SQLite database with the following schema:

```sql
CREATE TABLE packages (
  repo,
  packageName,
  packageManager,
  repoPath,
  filename,
  UNIQUE (repo, repoPath, packageName) ON CONFLICT IGNORE
);
```

#### Querying

Finally, once we'd loaded all the data in, I created the following script to allow querying the top direct and transitive dependencies per ecosystem:

```sh
#!/usr/bin/env bash
limit=$1
if [[ -z "$limit" ]]; then
  limit=20
fi

# ----- Go
m=GO
echo "Top $limit packages for $m (direct):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
AND filename NOT LIKE '%go.sum'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

echo "Top $limit packages for $m (including transitive):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

# ----- npm
m=NPM
echo "Top $limit packages for $m (direct):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
AND filename NOT LIKE '%yarn.lock' AND filename NOT LIKE '%package-lock.json'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

echo "Top $limit packages for $m (including transitive):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

# ----- Rubygems
m=RUBYGEMS
echo "Top $limit packages for $m (direct):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
AND filename NOT LIKE '%Gemfile.lock'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

echo "Top $limit packages for $m (including transitive):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

# ----- Maven
m=MAVEN
echo "Top $limit packages for $m:"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
AND filename NOT LIKE '%Cargo.lock'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

# ----- Pip
m=PIP
echo "Top $limit packages for $m (direct):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
AND filename NOT LIKE '%Pipfile.lock'
AND filename NOT LIKE '%pipfile.lock'
AND filename NOT LIKE '%poetry.lock'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

echo "Top $limit packages for $m (including transitive):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

# ----- Rust

m=RUST
echo "Top $limit packages for $m (direct):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
AND filename NOT LIKE '%Cargo.lock'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo

echo "Top $limit packages for $m (including transitive):"
sqlite3 db.db << EOF
.mode column
select packageName, COUNT(packageName)
from packages
WHERE packageManager = '$m'
GROUP BY packageName
ORDER BY COUNT(packageName) DESC
LIMIT $limit;
EOF
echo
```
