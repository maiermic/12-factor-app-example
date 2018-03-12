# 12-factor-app-example
Compose services of the 12 factor app example.

## Try it out online
Start a new playground on https://labs.play-with-docker.com

### Create Swarm
Add new instance (node1) and create a docker swarm:

```bash
docker swarm init --advertise-addr <ip-of-node1>
```

Copy the join command from the output that looks like this:

```bash
docker swarm join --token <token> <ip-of-node1>:<port>
``` 

Create another instance (node2) and join the swarm using the command above.

### Start the management UI
Let's start the management UI [Portainer](https://github.com/portainer/portainer)
using the terminal of **node1**:

```bash
docker run -d -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /opt/portainer:/data \
    --name=portainer \
    portainer/portainer
```

After a short time, a button "9000" (exposed port number of Portainer) should
be displayed next to the IP address field (fields above the terminal).
Click on it to open the Portainer UI.
You can access a service from outside (i.e. our browser) using the following
URL pattern:

```bash
http://ip<hyphen-ip>-<session_jd>-<port>.direct.labs.play-with-docker.com
```

If the SSH command of node1 is

```bash
ssh ip172-18-0-25-bagi9voo6i4000c4ab50@direct.labs.play-with-docker.com
```

open http://ip172-18-0-25-bagi9voo6i4000c4ab50-9000.direct.labs.play-with-docker.com
Portainer asks you to create the initial administrator user.
After that connect Portainer to the **local** Docker environment to get to the dashboard.

### Create secrets
Select *Secrets* in the navigation on the left side of Portainer.
Add the following secrets:

| name                | Secret        |
| :-------------------| :-------------|
| `mongo_user`        | `my-user`     |
| `mongo_password`    | `my-password` |
| `backend_api_token` | `my-token`    |


**Note:** You can also use the terminal instead of the UI:

```
echo my-user | docker secret create mongo_user -
echo my-password | docker secret create mongo_password -
echo my-token | docker secret create backend_api_token -
```

**Note:** Use files or the Portainer UI in production since the secret is
preserved in your shell history if you use `echo`:

```
docker secret create mongo_user mongo_user.txt
docker secret create mongo_password mongo_password.txt
docker secret create backend_api_token backend_api_token.txt
```

### Run the app
Go to the terminal of **node1** (in your Docker Playground) and run:

```bash
git clone https://github.com/maiermic/12-factor-app-example.git
cd 12-factor-app-example
mkdir -p volumes/database
mkdir -p volumes/file-storage
```

We need to configure some environment variables before we run the app.
First set `HYPHEN_IP` and `SESSION_JD` based on the values of your Docker
Playground:
```bash
export HYPHEN_IP=<hyphen-ip>
export SESSION_JD=<session_jd>
```

If the ssh command (see field above terminal) is

```bash
ssh ip172-18-0-25-bagi9voo6i4000c4ab50@direct.labs.play-with-docker.com
```

You set them to
```bash
export HYPHEN_IP=172-18-0-25
export SESSION_JD=bagi9voo6i4000c4ab50
```

Then set the other environment variables
```bash
export BACKEND_PORT=3001
export FILE_STORAGE_PORT=3002
export FRONTEND_PORT=3003
export BACKEND_BASE_IMAGE_URL="http://ip${HYPHEN_IP}-${SESSION_JD}-${FILE_STORAGE_PORT}.direct.labs.play-with-docker.com"
export BACKEND_URL="http://ip${HYPHEN_IP}-${SESSION_JD}-${BACKEND_PORT}.direct.labs.play-with-docker.com"
```

Now deploy the stack to run the services:

```bash
docker stack deploy -c docker-compose.yml 12-factor-app-example
```

The app is running, but if you go to the Portainer UI and select *Containers*
in the navigation on the left side you see that the backend containers stop
shortly after they have been started.
Click on the name of the last startet backend container to open the container
details page.
Click on *Logs* in the *Container status* section.
and open the logs
You see an error message:

```
Cannot connect to MongoDB! { MongoError: Authentication failed
```

The authentication to the database fails because we haven't created a user yet.
Let's fix this.

### Create database user
Connect to the database:

```bash
docker exec -ti \
    12-factor-app-example_database.1.$(docker service ps -f 'name=12-factor-app-example_database.1' 12-factor-app-example_database -q) \
    mongo admin
```

The sub-command returns the ID of the database container

```bash
docker service ps -f 'name=12-factor-app-example_database.1' 12-factor-app-example_database -q
```

You can also use tab-completion instead to get the full name of the
corresponding container.

**Note:** You can also open a terminal in the Portainer UI in the
*Container details* of the container `12-factor-app-example_database...`.

When you are connected to the database, create a new admin user

```
> db.createUser({ user: 'my-user', pwd: 'my-password', roles: [ { role: "userAdminAnyDatabase", db: "admin" } ] });
Successfully added user: {
	"user" : "my-user",
	"roles" : [
		{
			"role" : "userAdminAnyDatabase",
			"db" : "admin"
		}
	]
}

```

**Note:** In production you should use a less privileged user in the backend.

Exit the MongoDB client by running `exit`.
The backend should stay up running.
If you open the logs of the backend again you should see

```
secrets {
    "mongo_password": "my-password",
    "mongo_user": "my-user"
}
connect to database mongodb://database:27017/12-factor-app
Connected to MongoDB!
database name 12-factor-app
Server listening on port 3001!
```

### Try out the frontend
Open

```bash
http://ip<hyphen-ip>-<session_jd>-3003.direct.labs.play-with-docker.com
```

to try out the app.
You can upload images and show all uploaded images.

### Bonus - Monitoring

```
cd ~
git clone https://github.com/vegasbrianc/prometheus
cd prometheus
HOSTNAME=$(hostname) docker stack deploy -c docker-compose.yml prom
```

Open Grafana Dashboard on port `3000`

- **username:** `admin`
- **password:** `foobar` (Password is stored in the `/grafana/config.monitoring` env file)

Go to the *Docker Dashboard*.
You see several metrics.

Upload a large image ([10mb example](https://upload.wikimedia.org/wikipedia/commons/f/ff/Pizigani_1367_Chart_10MB.jpg))
to our frontend app and watch how the *Container Network Input* of the backend
and the file storage container increases.
If you download the image you will see a similar increase on the file storage container.