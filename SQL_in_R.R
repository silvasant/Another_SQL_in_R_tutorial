## SQL Con R

# Instalo los paquetes necesarios

# install.packages('RSQLite')

# Cargo librerias y configuro la coneccion a la bbdd
library(DBI)
library(tidyverse)
library(dbplyr)
library(lubridate)
# 2016 US presitential elections dataset
elecctions_con <- dbConnect(RSQLite::SQLite(), "data/_2016_US_elections_db.sqlite")
# Soccer matches database
con<-dbConnect(RSQLite::SQLite(), "data/soccer_database.sqlite")


# Podemos ver las tablas dentro del schema con dbListTables:
dbListTables(elecctions_con)
dbListTables(con)


# Podemos realizar queries de SQL directamente desde R.

# Rara traer info (SELECT statement)
QueryResult1<-dbGetQuery(conn = con,statement = 'select * from Match where league_id=1729
and date>=\'2013-01-01\'; ')
View(QueryResult1)
# Tambien se puede automatizar:

League_id<-1729
Date_value<-'2013-01-01'
QueryStatement1<-sprintf('select * from Match where league_id=%s and date>=\'%s\'; ',League_id,Date_value)
QueryStatement1
QueryResult1.2<-dbGetQuery(conn = con,statement = QueryStatement1)
View(QueryResult1.2)

# Otro ejmplo:

QueryStatement2 <-'select m.date,m.stage,m.home_team_goal,m.away_team_goal,team2.team_long_name home_team_name,team1.team_long_name away_team_name,
case when m.home_team_goal>m.away_team_goal then team2.team_long_name else case when m.home_team_goal<m.away_team_goal then team1.team_long_name else \'tie\'  end end winner_team_name
from Match m
left join team team1 on m.away_team_api_id = team1.team_api_id
left join team team2 on m.home_team_api_id = team2.team_api_id
where league_id=1729 and date>=\'2013-01-01\' order by date;'


QueryResult2<-dbGetQuery(conn = con,statement = QueryStatement2)

View(QueryResult2)


# Utilizando tidyverse

# funcion tbl() sirve para inicializar las tablas que vamos a utilizar:

Match<-tbl(con,'Match')
Team<-tbl(con,'Team')

# Ahora replicamos las queries de antes, usando tidyverse

Match %>% filter(date>='2013-01-01',league_id==1729)

# Esto nos muestra un preview de la query. Para traer la info a nuestra sesion tenemos que utilizar el comando collect()

Match %>% filter(date>='2013-01-01',league_id==1729) %>% collect() 


# El resultado de la query lo podemos asignar a un objeto, tanto antes de importarla como despues. Lo que cambia es el tipo de objeto:

QueryResult3<-Match %>% filter(date>='2013-01-01',league_id==1729)

QueryResult3.1<-Match %>% filter(date>='2013-01-01',league_id==1729) %>% collect()

data.class(QueryResult3) # Este resultado es basicamente una query
QueryResult3

data.class(QueryResult3.1) # Mientras que este es un tbl_df, una clase similar a un data.frame
QueryResult3.1


# Ahora recreamos la query mas compleja mediante tidyverse

Home_Team<-Team %>% select('home_team_api_id'=team_api_id,'home_team_name'=team_long_name)
Away_Team<-Team %>% select('away_team_api_id'=team_api_id,'away_team_name'=team_long_name)

Premier_Matches_With_TeamNames<-Match %>%
  filter(date >= '2013-01-01', league_id == 1729) %>%
  # select(date,stage,home_team_goal,away_team_goal,home_team_api_id,away_team_api_id) %>% # Esta linea de codigo es solo para emprolijar el print de la query.
  left_join(Home_Team, by = 'home_team_api_id') %>%
  left_join(Away_Team, by = 'away_team_api_id') %>%
  mutate('winner_team_name' = ifelse(
    home_team_goal > away_team_goal,
    home_team_name,
    ifelse(
      home_team_goal < away_team_goal,
      away_team_name,
      'tie'
    )
  )) %>%
  select(
    date,
    stage,
    home_team_goal,
    away_team_goal,
    home_team_name,
    away_team_name,
    winner_team_name
  )

Premier_Matches_With_TeamNames %>% collect() %>% View(title = 'Premier_Matches_With_TeamNames')

# Solo para comparar:

QueryStatement2 # Query con sintaxis tradicional de SQL

Premier_Matches_With_TeamNames %>% show_query() # Query utilizando tidyverse


# Otra ventaja de utilizar las funciones del tidyverse es que de manera sencilla se pueden realizar distintas operaciones: en la bbdd siempre y cuando las mismas se puedan traducir a una consulta de SQL, o se puede importar la info a la sesion de R y trabajarla localmente.


Premier_Matches_With_TeamNames %>%
  collect() %>%
  mutate('Year'=year(date)) %>%
  group_by(Year,winner_team_name) %>% 
  summarise('Max_winner'=n()) %>% View()






Premier_Matches_With_TeamNames %>%
  collect() %>%
  mutate('Year'=year(date)) %>% View('erer')

