--James Bloor
--CS779 Term Project
--Create statging tables and databse 


----------------create PitchData database----------------
CREATE DATABASE PitchData;
GO
USE PitchData;

----------------Now I have imported my data using SQL Server Management Studio Import CSV Tools----------------

----------------Look at staging tables----------------
Select TOP 5 * from ATBAT;
Select TOP 5 * from GAME;
Select TOP 5 * from PITCH;
Select TOP 5 * from PITCHRESULT;
Select TOP 5 * from PITCHTYPE;
Select TOP 5 * from PLAYERNAMES;
Select TOP 5 * from TEAMNAME;


----------------create Dimensional tables and stored procedures to populate tables----------------
CREATE TABLE GAME_DIM(
game_id					numeric(18,0)	NOT NULL,
home_team_name			nvarchar(50)	NOT NULL,
away_team_name			nvarchar(50)	NOT NULL,
home_final_score		tinyint			NOT NULL,
away_final_score		tinyint			NOT NULL,
game_date				date			NOT NULL,
venue_name				nvarchar(50)	NOT NULL

CONSTRAINT GAME_DIM_game_id_PK PRIMARY KEY (game_id));

CREATE TABLE ATBAT_DIM(
at_bat_id				int				NOT NULL,			
game_id					numeric(18,0)	NOT NULL,
batter_name				nvarchar(50)	NOT NULL,
pitcher_name			nvarchar(50)	NOT NULL,
inning					tinyint			NOT NULL,
top_of_inning			int				NOT NULL,
batter_stance			nvarchar(50)	NOT NULL,
pitcher_throws			nvarchar(50)	NOT NULL,
outs					tinyint			NOT NULL,
event					nvarchar(50)	NOT NULL

CONSTRAINT ATBAT_DIM_at_bat_id_PK PRIMARY KEY (at_bat_id)
CONSTRAINT ATBAT_DIM_game_id_FK FOREIGN KEY (game_id) REFERENCES GAME_DIM(game_id));


CREATE TABLE PITCH_DIM(
pitch_id			nvarchar(50)	NOT NULL,
at_bat_id			int				NOT NULL,
start_speed			float			,
end_speed			float			,
pitch_result_name	nvarchar(50)	,
pitch_type_name		nvarchar(50)	,
batter_team_score	tinyint			NOT NULL,
ball_count			tinyint			NOT NULL,
strike_count		tinyint			NOT NULL,
outs				tinyint			NOT NULL,
at_bat_pitch_count	tinyint			NOT NULL,
on_1b				tinyint			NOT NULL,
on_2b				tinyint			NOT NULL,
on_3b				tinyint			NOT NULL

CONSTRAINT PITCH_DIM_pitch_id_PK PRIMARY KEY (pitch_id)
CONSTRAINT PITCH_DIM_at_bat_id_FK FOREIGN KEY (at_bat_id) REFERENCES ATBAT_DIM(at_bat_id));


----------------test below to create a view that we want to put in our dim tables above----------------
--procedure below updates the GAME_DIM table
GO
Create or Alter Procedure Load_GAME_DIM
as
Begin
--insert data into table
	Begin
	insert into GAME_DIM
	(game_id,home_team_name,away_team_name,home_final_score,away_final_score,game_date,venue_name)
	Select
	game_id,home_team_name,away_team_name,home_final_score,away_final_score,date as game_date,venue_name
	from GAME gm
	left join (select team_abri, team_name as home_team_name from TEAMNAME h)h on gm.home_team = h.team_abri
	left join (select team_abri, team_name as away_team_name from TEAMNAME a)a on  gm.away_team = a.team_abri
	--makes sure that there isn't any duplicate data being added
	where not exists(
		select 1 
		from GAME_DIM gmd
		where gmd.game_id = gm.game_id)
	End;
--update exisiting records if anything has changed
	Begin
	Update gmd
	set
	gmd.game_id = gm.game_id,gmd.home_team_name = gm.home_team_name,gmd.away_team_name = gm.away_team_name,
	gmd.home_final_score = gm.home_final_score,gmd.away_final_score = gm.away_final_score,
	gmd.game_date = gm.game_date,gmd.venue_name = gm.venue_name
	from GAME_DIM gmd
	join(
	Select
	game_id,home_team_name,away_team_name,home_final_score,away_final_score,date as game_date,venue_name
	from GAME gm
	left join (select team_abri, team_name as home_team_name from TEAMNAME h) h on gm.home_team = h.team_abri
	left join (select team_abri, team_name as away_team_name from TEAMNAME a)a on  gm.away_team = a.team_abri
	) gm
	on gmd.game_id = gm.game_id
	End;
End;
GO

--procedure below updates the ATBAT_DIM table
GO
Create or Alter Procedure Load_ATBAT_DIM
as
Begin
--insert data into table
	Begin
	insert into ATBAT_DIM
	(at_bat_id,game_id,batter_name,pitcher_name,inning,top_of_inning,batter_stance,pitcher_throws,outs,event)
	Select
	at_bat_id,game_id,concat(batter_first_name,' ', batter_last_name) as batter_name,
	concat(pitcher_first_name,' ', pitcher_last_name) as pitcher_name,inning,top_of_inning,batter_stance,pitcher_throws,outs,event	
	from ATBAT a
	left join (select first_name as batter_first_name, last_name as batter_last_name, player_id as player_id_batter from PLAYERNAMES d)
	d on a.batter_id = d.player_id_batter
	left join (select first_name as pitcher_first_name,last_name as pitcher_last_name,player_id as player_id_batter from PLAYERNAMES p)
	p on  a.pitcher_id = p.player_id_batter
	--makes sure that there isn't any duplicate data being added
	where not exists(
		select 1 
		from ATBAT_DIM ad
		where ad.at_bat_id = a.at_bat_id)
	End;
--update exisiting records if anything has changed
	Begin
	Update ad
	set
	ad.at_bat_id = a.at_bat_id,ad.game_id= a.game_id,ad.batter_name= a.batter_name,ad.pitcher_name= a.pitcher_name,ad.inning= a.inning,
	ad.top_of_inning= a.top_of_inning,ad.batter_stance= a.batter_stance,ad.pitcher_throws= a.pitcher_throws,ad.outs= a.outs,ad.event= a.event
	from ATBAT_DIM ad
	join(Select
	at_bat_id,game_id,concat(batter_first_name,' ', batter_last_name) as batter_name,
	concat(pitcher_first_name,' ', pitcher_last_name) as pitcher_name,inning,top_of_inning,batter_stance,pitcher_throws,outs,event	
	from ATBAT a
	left join (select first_name as batter_first_name, last_name as batter_last_name, player_id as player_id_batter from PLAYERNAMES d)
	d on a.batter_id = d.player_id_batter
	left join (select first_name as pitcher_first_name,last_name as pitcher_last_name,player_id as player_id_batter from PLAYERNAMES p)
	p on  a.pitcher_id = p.player_id_batter
	) a
	on ad.at_bat_id = a.at_bat_id
	End;
End;
GO
 
--procedure below updates the PITCH_DIM table
GO
Create or Alter Procedure Load_PITCH_DIM
as
Begin
--insert data into table
	Begin
	insert into PITCH_DIM
	(pitch_id,at_bat_id,start_speed,end_speed,pitch_result_name,pitch_type_name,batter_team_score,ball_count,strike_count,outs,
	at_bat_pitch_count,on_1b,on_2b,on_3b)
	Select
	pitch_id,at_bat_id,start_speed,end_speed,pitch_result_name,pitch_type_name,batter_team_score,ball_count,strike_count,outs,
	at_bat_pitch_count,on_1b,on_2b,on_3b		
	from PITCH p
	left join PITCHRESULT on p.pitch_result = PITCHRESULT.pitch_result
	left join PITCHTYPE on p.pitch_type = PITCHTYPE.pitch_type
	--makes sure that there isn't any duplicate data being added
	where not exists(
		select 1 
		from PITCH_DIM pd
		where pd.pitch_id = p.pitch_id)
	End;
--update exisiting records if anything has changed
	Begin
	Update pd
	set
	pd.pitch_id = p.pitch_id,pd.at_bat_id = p.at_bat_id,pd.start_speed = p.start_speed,pd.end_speed = p.end_speed,
	pd.pitch_result_name = p.pitch_result_name,pd.pitch_type_name = p.pitch_type_name,pd.batter_team_score = p.batter_team_score,
	pd.ball_count = p.ball_count,pd.strike_count = p.strike_count,pd.outs = p.outs,pd.at_bat_pitch_count = p.at_bat_pitch_count,
	pd.on_1b = p.on_1b,pd.on_2b = p.on_2b,pd.on_3b = p.on_3b	
	from PITCH_DIM pd
	join(
	Select
	pitch_id,at_bat_id,start_speed,end_speed,pitch_result_name,pitch_type_name,batter_team_score,ball_count,strike_count,outs,
	at_bat_pitch_count,on_1b,on_2b,on_3b	
	from PITCH
	left join PITCHRESULT on PITCH.pitch_result = PITCHRESULT.pitch_result
	left join PITCHTYPE on PITCH.pitch_type = PITCHTYPE.pitch_type
	) p
	on pd.pitch_id = p.pitch_id
	End;
End;
GO


----------------call store procudures to fill dimensional tables and test deletion---------------- 
exec Load_GAME_DIM;
select top 5 * from GAME_DIM;
DELETE FROM GAME_DIM WHERE game_id = 201900001;
select top 5 * from GAME_DIM;
exec Load_GAME_DIM;
select top 5 * from GAME_DIM;

exec Load_ATBAT_DIM;
select top 5 * from ATBAT_DIM;
DELETE FROM ATBAT_DIM WHERE at_bat_id = 2019000001;
select top 5 * from ATBAT_DIM;
exec Load_ATBAT_DIM;
select top 5 * from ATBAT_DIM;

exec Load_PITCH_DIM;
select top 5 * from PITCH_DIM;
DELETE FROM PITCH_DIM WHERE pitch_id = '2019000001-1';
select top 5 * from PITCH_DIM;
exec Load_PITCH_DIM;
select top 5 * from PITCH_DIM;

----------------create layout for fact tables----------------
CREATE TABLE PITCHEVENTCOUNT_FACT(
batter_name				nvarchar(50)	NOT NULL,
pitcher_name			nvarchar(50)	NOT NULL,
event					nvarchar(50)	NOT NULL,
event_count				int				NOT NULL)

CREATE TABLE GAMESUM_FACT(
home_team_name			nvarchar(50)	NOT NULL,
away_team_name			nvarchar(50)	NOT NULL,
home_team_avg			FLOAT			NOT NULL,
away_team_avg			FLOAT			NOT NULL,
home_team_total			int				NOT NULL,
away_team_total			int				NOT NULL)

CREATE TABLE PITCHTYPECOUNT_FACT(
batter_name				nvarchar(50)	NOT NULL,
pitcher_name			nvarchar(50)	NOT NULL,
pitch_type_name			nvarchar(50)	,
pitch_type_count		int				NOT NULL)

CREATE TABLE PITCHRESULTCOUNT_FACT(
batter_name				nvarchar(50)	NOT NULL,
pitcher_name			nvarchar(50)	NOT NULL,
pitch_result_name		nvarchar(50)	,
pitch_result_count		int				NOT NULL)

CREATE TABLE PITCHERBATTER_FACT(
pitch_id				nvarchar(50)	NOT NULL,
at_bat_id				int				NOT NULL,
batter_name				nvarchar(50)	NOT NULL,
pitcher_name			nvarchar(50)	NOT NULL,
batter_stance			nvarchar(50)	NOT NULL,
pitcher_throws			nvarchar(50)	NOT NULL,
inning					tinyint			NOT NULL,
top_of_inning			int				NOT NULL,
pitch_result_name		nvarchar(50)	,
pitch_type_name			nvarchar(50)	,
batter_team_score		tinyint			NOT NULL,	 
ball_count				tinyint			NOT NULL,
strike_count			tinyint			NOT NULL,
outs					tinyint			NOT NULL,
at_bat_pitch_count		tinyint			NOT NULL,
on_1b					tinyint			NOT NULL,
on_2b					tinyint			NOT NULL,
on_3b					tinyint			NOT NULL,
game_date				DATE			NOT NULL,
venue_name				nvarchar(50)	NOT NULL

CONSTRAINT PITCHERBATTER_FACT_pitch_id_PK PRIMARY KEY (pitch_id))


----------------create procudures that populate fact tables---------------- 
--procedure below updates the PITCHEVENTCOUNT_FACT table
Go
Create or Alter Procedure Load_PITCHEVENTCOUNT_FACT
as
Begin
--empty fact table and refresh it
Truncate table PITCHEVENTCOUNT_FACT;
--add data back inot the table
Begin
insert into PITCHEVENTCOUNT_FACT
(batter_name,pitcher_name,event,event_count)
select 
batter_name,pitcher_name,event,count(*) as event_count
from ATBAT_DIM
group by batter_name,pitcher_name,event
Order by event_count desc
End;
End;
Go

--procedure below updates the GAMESUM_FACT table
Go
Create or Alter Procedure Load_GAMESUM_FACT
as
Begin
--empty fact table and refresh it
Truncate table GAMESUM_FACT;
--add data back inot the table
Begin
insert into GAMESUM_FACT
(home_team_name,away_team_name,home_team_avg,away_team_avg,home_team_total,away_team_total)
select
home_team_name,away_team_name,avg(home_final_score) as home_team_avg,avg(away_final_score) as away_team_avg,
sum(home_final_score) as home_team_total,sum(away_final_score) as away_team_total
from GAME_DIM
group by home_team_name,away_team_name
End;
End;
Go

--procedure below updates the PITCHTYPECOUNT_FACT table
Go
Create or Alter Procedure Load_PITCHTYPECOUNT_FACT
as
Begin
--empty fact table and refresh it
Truncate table PITCHTYPECOUNT_FACT;
--add data back inot the table
Begin
insert into PITCHTYPECOUNT_FACT
(batter_name,pitcher_name,pitch_type_name,pitch_type_count)
select
batter_name,pitcher_name,pitch_type_name,count(*) as pitch_type_count
from PITCH_DIM
left join ATBAT_DIM on PITCH_DIM.at_bat_id = ATBAT_DIM.at_bat_id
group by batter_name, pitcher_name,pitch_type_name
Order by pitch_type_count desc
End;
End;
Go

--procedure below updates the PITCHRESULTCOUNT_FACT table 
Go
Create or Alter Procedure Load_PITCHRESULTCOUNT_FACT
as
Begin
--empty fact table and refresh it
Truncate table PITCHRESULTCOUNT_FACT;
--add data back inot the table
Begin
insert into PITCHRESULTCOUNT_FACT
(batter_name,pitcher_name,pitch_result_name,pitch_result_count)
select
batter_name,pitcher_name,pitch_result_name,count(*) as pitch_result_count
from PITCH_DIM
left join ATBAT_DIM on PITCH_DIM.at_bat_id = ATBAT_DIM.at_bat_id
group by batter_name, pitcher_name,pitch_result_name
Order by pitch_result_count desc
End;
End;
Go

--procedure below updates the PITCHERBATTER_FACT table 
Go
Create or Alter Procedure Load_PITCHERBATTER_FACT
as
Begin
--empty fact table and refresh it
Truncate table PITCHERBATTER_FACT;
--add data back inot the table
Begin
insert into PITCHERBATTER_FACT
(pitch_id,at_bat_id,batter_name,pitcher_name,batter_stance,pitcher_throws,inning,top_of_inning,pitch_result_name,pitch_type_name,
batter_team_score,ball_count,strike_count,outs,at_bat_pitch_count,on_1b,on_2b,on_3b,game_date,venue_name)
select
pitch_id,PITCH_DIM.at_bat_id,batter_name,pitcher_name,batter_stance,pitcher_throws,inning,top_of_inning,pitch_result_name,pitch_type_name,
batter_team_score,	 ball_count,strike_count,PITCH_DIM.outs,at_bat_pitch_count,on_1b,on_2b,on_3b,game_date,venue_name
from PITCH_DIM
left join ATBAT_DIM on PITCH_DIM.at_bat_id = ATBAT_DIM.at_bat_id
left join GAME_DIM on GAME_DIM.game_id = ATBAT_DIM.game_id
End;
End;
Go

----------------call store procudures to fill fact tables---------------- 
exec Load_PITCHEVENTCOUNT_FACT;
select top 5 * from PITCHEVENTCOUNT_FACT;
exec Load_GAMESUM_FACT;
select top 5 * from GAMESUM_FACT;
exec Load_PITCHTYPECOUNT_FACT;
select top 5 * from PITCHTYPECOUNT_FACT;
exec Load_PITCHRESULTCOUNT_FACT;
select top 5 * from PITCHRESULTCOUNT_FACT;
exec Load_PITCHERBATTER_FACT;
select top 5 * from PITCHERBATTER_FACT;

