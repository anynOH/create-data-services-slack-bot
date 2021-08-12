# create-data-services-slack-bot

This Slack-Bot implements [Slash-Commands](https://api.slack.com/interactivity/slash-commands) to trigger builds from the [Create-Data-Services-Pipeline](https://ci.dev1.a9s-ops.de/teams/main/pipelines/create-data-services) from within Slack.  
The following commands are available:  

- `/create <data-service>` : trigger the requested job

# Development

This section will explain how to adapt or improve the bot with new or different functionalities.

## Slack API Configuration

In order for the Bot to be available, it is managed in the [Slack App Portal](https://api.slack.com/apps/A027T3WT0LD).  
Slash-command endpoints and Slack credentials are managed here.  
New Slash-commands can be added under the `Slash Commands` section.

## Web Endpoint

The Bot uses [sinatra](http://sinatrarb.com/) as the Web-framework.  
Creating a new endpoit is pretty straight forward and can be looked up in the sinatra documentation.  
The endpoint simply receives the requests, checks authenticity (see [Slack documentation](https://api.slack.com/)) and spawns a new Thread which will then process the request.  
We need to process the request in a new Thread as the Bot needs to respond with 200 OK as a receipt for the request within a small time-window.

## Bot Implementation

### Processing Requests

All Requests originating from the invocation of a slash-command will be processed by the `Bot`-Class.  
The request contains information like `user_id` or `text` which are relevant for triggering Concourse-Jobs and creating responses.  
These can be accessed by using `params[:<fieldname>]`. A list of available parameters can be found [here](https://api.slack.com/interactivity/slash-commands#app_command_handling).

### Triggering Concourse Jobs

The Bot uses [fly-CLI](https://concourse-ci.org/fly.html) to interact with anynines-Concourse.  
The workflow of triggering new jobs looks like this (exemplary):  

1. User invokes `/create postgres`
2. Bot receives the request and maps `params[:text]` to a jobname in `config/config.yml`
3. Bot triggers the job by calling `ConcourseUtils.trigger_and_watch` and gets back the deployment-name

### Responding to Users

After the Data-Service has been successfully created, the Bot will inform the user about his / her new deployment.  
Responses can be `ephemeral` or `in_channel`. Ephemeral messages will only be visible to one user while in_channel messages are visible to everyone.  
To create another response you can use `Bot.respond` or use parameters like `response_url` to create your own HTTP-response.

### Automatic renaming of service-prefixes

TODO

# Deployment

This app is shipped and deployed as a BOSH-Release
