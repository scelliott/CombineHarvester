# CombineHarvester

         ___                _     _                                            _
        / __\___  _ __ ___ | |__ (_)_ __   ___  /\  /\__ _ _ ____   _____  ___| |_ ___ _ __
       / /  / _ \| '_ ` _ \| '_ \| | '_ \ / _ \/ /_/ / _` | '__\ \ / / _ \/ __| __/ _ \ '__|
      / /__| (_) | | | | | | |_) | | | | |  __/ __  / (_| | |   \ V /  __/\__ \ ||  __/ |
      \____/\___/|_| |_| |_|_.__/|_|_| |_|\___\/ /_/ \__,_|_|    \_/ \___||___/\__\___|_|

##### Combine the results of TheHarvester
- Multi Threaded (Kinda)
- Parses out human/non-human email addresses
- Enumerates likely organisation naming convention
- Turns names into email addresses
- Builds CSV of found names & email addresses

##### Usage
combineharvester domain


##### Outputs
- human.domain.com.csv: CSV of names and email addresses of real people
- nothuman.domain.com.txt: TXT of shared/non identifying mailboxes


Based on the awesome work of Christian Martorella
- https://github.com/laramies/theHarvester
