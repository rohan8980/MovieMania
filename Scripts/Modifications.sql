We have various different files namely Movies.csv, Links.csv, Tags.csv, Ratings.csv, and ml-youtube.csv. For all the files the data was first loaded into the temporary tables before loading them into the main tables. This is because data files are usually not in proper data formats for the main table. For instance MovieID or UserID which is expected to be a integer or numeric data type could be of string or some random junk values due either due to error or due to improper formating issue. Thus it was loaded into temporary table where all the data types are text for all the columns so that we would clean the data there and then load it into the main table. For Movies.csv the data encoding was different along with the field sepeartor. By using proper delimiter and encoding data was loaded into temporary table and then MovieID was checked and updated to bigint. This clean data was moved to the main table Movies where MovieID is the primary key. At the end temporary table was dropped. Similarly data was loaded using proper delimeters and encoding data was loaded into temporary tables for rest of the 4 files and data was moved to main table after verfying the data types and junk data for the columns. 

From Movies table we had multiple Genres which were seperated from the Movies table and a master table was created named Genres_Master which contained all the distinct genres across all the movies. This table had ID as primary key which was linked to another table named Genres which contained the GenreId from the Genres_Master and MovieID from Movies table to stores what all genres are linked to all movies. In the similar manner from the Tags table unique Tags were identified and Tags_Master table was created with ID as the primary key. Tags table is not linked to the newly created Tags_Master table with Foreign key of its column TagID with the ID column from the Tags_Master. So now tags table has TagID which is linked to the tag in Tags_Master table and MovieID which is linked to the movieid in the Movies table. Another change that was carried out was that both the Links table and Youtube table has links of the movies with the MovieID as the Foreign key to the Movies table. Thus it was unneccesary redundancy so merged these both tables into the Movies table. For this 3 new columns were created in the movies table namely ImdbID, TmdbID for the Links table and YoutubeID for the Youtube table. After this action both Links and Youtube tables can be created. The last change that was carried was that MovieLinks table was created to store full links instead of just IDs in the Movies Table. This is created keeping in mind the fact that the availability of the direct links without any concatination would save up some time and boost efficiency for the front end. This table is linked to the Movies table obviously through the MovieID column.




------------------ TASK 5 ----------------
We faced couple of issues with handling this dataset. First issue faced was during the loading of the data from the files. There were multiple files for each table from which the initial data was loaded. The issue was that the CSV files have varying formats or say has different formats. For instance some files has double quotes as the field terminator not for all the columns but for one or two columns only. In addition to this, the double quotes was not for all the rows of that column but for random rows. This made it challanging to load the data for all the files in a unified format. So we have to write different data load syntax for each file to load the data successfully. Another issue faced was with the Ratings file. This file has more than 2 million entries. It took significant amount of time to load the data into the temporary table due to the huge size of the data. Furthermore, for the modification of the data types of these columns before loading them into the main permenant table, also took considerable amount of time. As this was data load process from file to our table and to make it faster we have already used the temporary table. This is because the temporary tables works in memory and are always faster than the main table. Here surely indexing would have helped but it would be totally wastage of space because temporary table is eventually going to be deleted and it was created with sole purpose for data cleaning and faster loading of data from the file to main table.



---------------------- TASK 6 ------------------------
--1--Movies with highest average ratings  (Atleast 1000 ratings)
SELECT M.Title, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
FROM Ratings R
INNER JOIN Movies M ON M.MovieID = R.MovieID
GROUP BY M.Title
HAVING COUNT(*) > 1000
ORDER BY CAST(AVG(Rating) AS NUMERIC(10,2)) DESC, COUNT(*) DESC;



--2--Number of Ratings per Genre
SELECT GM.Genre, COUNT(*) Ratings, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating 
FROM Genres G
INNER JOIN Ratings R ON R.MovieID = G.MovieID
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
GROUP BY GM.Genre
ORDER BY COUNT(*) DESC;



--3--Top 3 Movies with highest rankings in Each Genre (at least 1000 ratings)
SELECT MG.Genre, T.Title, T.Rating, T.Rankings
FROM (
    SELECT M.Title, G.GenreID, CAST(AVG(R.Rating) AS NUMERIC(10,2)) Rating, 
		   RANK() OVER(PARTITION BY G.GenreID ORDER BY AVG(R.Rating) DESC) Rankings
    FROM Movies M
    INNER JOIN Ratings R ON M.MovieID = R.MovieID
    INNER JOIN Genres G ON M.MovieID = G.MovieID
    GROUP BY M.MovieID, G.GenreID
	HAVING COUNT(*) > 1000
	
) as T
INNER JOIN Genres_Master MG ON MG.ID = T.GenreID
WHERE T.Rankings <= 3
ORDER BY MG.Genre, T.Rankings;



--4--Average rating of Movies Tag wise
SELECT TM.Tag, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
FROM Tags T
INNER JOIN Ratings R ON R.MovieID = T.MovieID
INNER JOIN Tags_Master TM ON TM.ID = T.TagID
GROUP BY TM.Tag
HAVING COUNT(*) > 1000
ORDER BY 2 DESC, 3 DESC;
/*
	---- OR ----

WITH TagwiseRatings AS (
	SELECT T.TagID, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
	FROM Tags T
	INNER JOIN Ratings R ON R.MovieID = T.MovieID
	GROUP BY T.TagID
	HAVING COUNT(*) > 1000
	--ORDER BY CAST(AVG(Rating) AS NUMERIC(10,2)) DESC
)
SELECT TM.Tag, TR.Rating, TR.Ratings
FROM TagwiseRatings TR
INNER JOIN Tags_Master TM ON TM.ID = TR.TagID
ORDER BY TR.Rating DESC, TR.Ratings DESC;
*/



--5--Most Popular Tags
SELECT TM.Tag, COUNT(*) Tag_Count
FROM Tags_Master TM
INNER JOIN Tags T ON T.TagID = TM.ID
GROUP BY TM.Tag
ORDER BY COUNT(*) DESC;


--6--Movies with specific Genres
SELECT M.Title "Movie Name", GM.Genre
FROM Movies M
INNER JOIN Genres G ON G.MovieID = M.MovieId
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
WHERE GM.Genre = 'Sci-Fi';


--7--Movies with specific Tags
SELECT M.Title "Movie Name", TM.Tag
FROM Movies M
INNER JOIN Tags T ON T.MovieID = M.MovieId
INNER JOIN Tags_Master TM ON TM.ID = T.TagID
WHERE Tag = 'Science Fiction';





--8--Updating missing links in the MovieLinks from the Movies
UPDATE MovieLinks ML
SET ImdbLink = 'http://www.imdb.com/title/tt' || LTRIM(RTRIM(M.ImdbID)),
	TmdbLink = 'https://www.themoviedb.org/movie/' || LTRIM(RTRIM(M.TmdbID)),
	YoutubeLink = 'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(M.YoutubeID))
FROM Movies M 
WHERE M.MovieID = ML.MovieID
  AND (
	  	(M.ImdbID IS NOT NULL AND ML.ImdbLink IS NULL)
   	 OR (M.TmdbID IS NOT NULL AND ML.TmdbLink IS NULL)
   	 OR (M.YoutubeID IS NOT NULL AND ML.YoutubeLink IS NULL)
	  );
	  
--9--Identify and delete a movie which is only present in Movies and neither in Tags nor in Ratings
--Identify and delete Genres first due to FK dependency
DELETE --SELECT *
FROM Genres G
WHERE 1=1
  AND NOT EXISTS (SELECT 1 FROM Ratings R WHERE R.MovieID = G.MovieID)
  AND NOT EXISTS (SELECT 1 FROM Tags T WHERE T.MovieID = G.MovieID);
  
DELETE --SELECT * 
FROM Movies M
WHERE 1=1
  AND NOT EXISTS (SELECT 1 FROM Ratings R WHERE R.MovieID = G.MovieID)
  AND NOT EXISTS (SELECT 1 FROM Tags T WHERE T.MovieID = G.MovieID);




/*
SELECT MAX(MovieID) FROM Movies;
CREATE SEQUENCE movies_movieid_seq START WITH 131263;
ALTER TABLE Movies ALTER COLUMN movieid SET DEFAULT nextval('movies_movieid_seq');
--SELECT MAX(movieid) FROM Movies; --131262
--ALTER SEQUENCE movies_movieid_seq RESTART WITH 131263;


--SELECT MAX(ID) FROM MovieLinks;
--CREATE SEQUENCE movielinks_id_seq START WITH 27279;
--ALTER TABLE MovieLinks ALTER COLUMN ID SET DEFAULT nextval('movielinks_id_seq');
*/

--10--Insert New Movie
DO $$
DECLARE
    v_Title text := 'Dune: Part Two';
    v_ImdbID text := '15239678';
    v_TmdbID text := '693134';
    v_YoutubeID text := 'GMF7wbhBJKY';
	v_Year integer := 2023;
BEGIN
    INSERT INTO Movies (Title, ImdbID, TmdbID, YoutubeID, Year)
    VALUES (v_Title, v_ImdbID, v_TmdbID, v_YoutubeID, v_Year);
END $$;
SELECT * FROM Movies WHERE Title = 'Dune: Part Two' ORDER BY MovieID DESC LIMIT 1;


--11--Insert Links of the Movie
DO $$
DECLARE
    v_Title text := 'Dune: Part Two';
	v_ImdbID text;
    v_TmdbID text;
    v_YoutubeID text;
	v_MovieID bigint;
BEGIN
	SELECT MovieID, ImdbID, TmdbID, YoutubeID 
    INTO v_MovieID, v_ImdbID, v_TmdbID, v_YoutubeID  
	FROM Movies WHERE Title = v_Title LIMIT 1;
	
    INSERT INTO MovieLinks (MovieID, ImdbLink, TmdbLink, YoutubeLink)
	SELECT v_MovieID, 
		   'https://www.imdb.com/title/tt' || v_ImdbID || '/' ImdbID,
		   'https://www.themoviedb.org/movie/' || v_TmdbID TmdbID,
		   'https://www.youtube.com/watch?v=' || v_YoutubeID YoutubeID;
END $$;
SELECT * FROM MovieLinks WHERE MovieID = (SELECT MovieID FROM Movies WHERE Title = 'Dune: Part Two');

  
--12--Update Movies.Year
DO $$
DECLARE
    v_Title text := 'Dune: Part Two';
	v_NewYear integer := 2024;
	v_MovieID bigint;
BEGIN
    SELECT MovieID INTO v_MovieID FROM Movies WHERE Title = v_Title LIMIT 1;
    
	UPDATE Movies
	SET Year = v_NewYear
	WHERE MovieID = v_MovieID;
END $$;
SELECT * FROM Movies WHERE Title = 'Dune: Part Two';


--13--Updating New Trailer Link
DO $$
DECLARE
    v_Title text := 'Dune: Part Two';
	v_NewTrailer text := '_YUzQa_1RCE';
	v_MovieID bigint;
BEGIN
    SELECT MovieID INTO v_MovieID FROM Movies WHERE Title = v_Title LIMIT 1;
    
	UPDATE Movies
	SET YoutubeID = v_NewTrailer
	WHERE MovieID = v_MovieID;
	
	UPDATE MovieLinks
	SET YoutubeLink = 'https://www.youtube.com/watch?v=' || v_NewTrailer
	WHERE MovieID = v_MovieID;
END $$;
SELECT * FROM Movies WHERE Title = 'Dune: Part Two';
SELECT * FROM MovieLinks ORDER BY 1 DESC LIMIT 1;


--14--Deleting MovieLinks of Movie
SELECT * FROM MovieLinks WHERE MovieID = (SELECT MovieID FROM Movies WHERE Title = 'Dune: Part Two');
DO $$
DECLARE
    v_Title text := 'Dune: Part Two';
	v_MovieID bigint;
BEGIN
    SELECT MovieID INTO v_MovieID FROM Movies WHERE Title = v_Title LIMIT 1;
    
	DELETE FROM MovieLinks
	WHERE MovieID = v_MovieID;
END $$;
SELECT * FROM MovieLinks WHERE MovieID = (SELECT MovieID FROM Movies WHERE Title = 'Dune: Part Two');


--15--Deleting Specific Movie from Movies
SELECT * FROM Movies WHERE Title = 'Dune: Part Two' ORDER BY MovieID DESC LIMIT 1;
DO $$
DECLARE
    v_Title text := 'Dune: Part Two';
	v_MovieID bigint;
BEGIN
    SELECT MovieID INTO v_MovieID FROM Movies WHERE Title = v_Title LIMIT 1;
    
	DELETE FROM Movies
	WHERE MovieID = v_MovieID;
	  
END $$;
SELECT * FROM Movies WHERE Title = 'Dune: Part Two' ORDER BY MovieID DESC LIMIT 1;



  

  
  



---------------- TASK 7 -------------------
--1--Average rating of Movies Tag wise
EXPLAIN SELECT TM.Tag, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
FROM Tags T
INNER JOIN Ratings R ON R.MovieID = T.MovieID
INNER JOIN Tags_Master TM ON TM.ID = T.TagID
GROUP BY TM.Tag
HAVING COUNT(*) > 1000
ORDER BY 2 DESC, 3 DESC
LIMIT 25

SELECT TM.Tag, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
FROM Tags T
INNER JOIN Ratings R ON R.MovieID = T.MovieID AND R.UserID = T.UserID
INNER JOIN Tags_Master TM ON TM.ID = T.TagID
GROUP BY TM.Tag
HAVING COUNT(*) > 1000
ORDER BY 2 DESC, 3 DESC
LIMIT 25

-- For this query it was taking around 6-7 minutes for execution due to huge size of data. From Explain found out that it was doing 3 Sequential table scan for all the rows and was slow as Primary key index was on combination of UserId, MovieID and we were only using MovieID in the join condition. Thus added the existing index condition in the join R.UserID = T.UserID and the performance drastically improved and query results in just couple of seconds. The other approach that we could have taken was to create a new table which contains a single entry for storing the average rating and number of ratings for all the movies. This would drastically improve the efficiency of all the queries as we would be traversing only 27278 rows which is single rows for each movie instead of traversing and aggregating results from all the 20000263 ratings by all the users. But doing this would result in loss of users data but we can assume that users who rated the ratings are not so important here as we do not have the data of the users and we only require the average and total number of ratings for a movie.



--2-- Movies with most number of ratings
EXPLAIN SELECT M.Title, COUNT(*) Ratings
FROM Ratings R
INNER JOIN Movies M ON M.MovieID = R.MovieID
GROUP BY M.Title
ORDER BY COUNT(*) DESC

--3.5 seconds
CREATE INDEX idx_ratings_movieID ON Ratings (MovieID);
SELECT M.Title, COUNT(*) Ratings
FROM Ratings R
INNER JOIN Movies M ON M.MovieID = R.MovieID
GROUP BY M.Title
ORDER BY COUNT(*) DESC
DROP INDEX IF EXISTS idx_ratings_movieID;

-- For this query we were selecting movies with most number of ratings. In this query it was taking roughly 5.5 seconds for each execution. The thing to notice here was that the Primary key index for the Ratings table was present on the combination of the columns UserId and MovieID. Unfortunately we were using only the MovieId in our join for this query and thus not utilizing the index and doing whole table sequential scan for this query. Thus we created a non clustered index on just the MovieID column and thereby improving the performance roughly by 40%. Now the query utilizes the new index and takes just 3.5 seconds which was taking 5.5 seconds.



--3-- Fetching Movies Yearwise in Range
EXPLAIN SELECT M.Title, GM.Genre, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings 
FROM Movies M
INNER JOIN Genres G ON G.MovieID = M.MovieID
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
INNER JOIN Ratings R ON R.MovieID = M.MovieID
WHERE (
	    Title LIKE '%2010%'
   	 OR Title LIKE '%2011%'
   	 OR Title LIKE '%2012%'
   	 OR Title LIKE '%2013%'
   	 OR Title LIKE '%2014%'
     OR Title LIKE '%2015%'
	   ) 
GROUP BY M.Title, GM.Genre	   


UPDATE Movies SET Title = LTRIM(RTRIM(Title))
CREATE TEMPORARY TABLE Year_Temp AS
SELECT MovieId, title, SUBSTRING(Title, LENGTH(Title) - POSITION('(' IN REVERSE(Title)) + 2, 4) AS Year
FROM Movies
UPDATE Year_Temp SET Year = NULL WHERE NOT Year ~ E'^\\d+$'

ALTER TABLE Movies ADD COLUMN Year INT;
UPDATE Movies M
SET Year = CAST(T.Year AS INT)
FROM Year_Temp T
WHERE M.MovieId = T.MovieId;
DROP TABLE IF EXISTS Year_Temp

SELECT M.Title, GM.Genre, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings 
FROM Movies M
INNER JOIN Genres G ON G.MovieID = M.MovieID
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
INNER JOIN Ratings R ON R.MovieID = M.MovieID
WHERE M.Year BETWEEN 2010 AND 2015 
GROUP BY M.Title, GM.Genre


--Here for this query we wanted to search and filter the movies year wise either for a specific year or for range of years like latest movies of last 5 years then we would have to do a table scan for Title column of Movies table and use Like operator to search for the year. This affects the performance of the query because we will be checking through each row and then each character in the title to search for the year. Thus it would be far more better if we could create different column for year in our table. Thus we have separated the column "year" from the title column of movies table. Then querying the year directly from this new column instead of the traversing each title would be much more faster and efficient for range or filter queries.















/*-- Summary Table to boost speed x10
CREATE TABLE Ratings_Summary AS
SELECT MovieID, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
FROM Ratings
GROUP BY MovieID;

ALTER TABLE Ratings_Summary ADD PRIMARY KEY (MovieID);


# Home Query
SELECT M.Title, string_agg(GM.Genre, ', ') AS Genres, 
	   'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer,
	   MAX(R.Rating) Ratings, MAX(R.Ratings) Ratings 
FROM Movies M
INNER JOIN Ratings_Summary R ON R.MovieID = M.MovieID
INNER JOIN Genres G on G.MovieID = M.MovieID
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
WHERE M.Title = 'Heat (1995)'
GROUP BY M.MovieID, M.Title, M.Year
ORDER BY MAX(R.Rating) DESC, MAX(R.Ratings) DESC, M.MovieID


# Search by Year
SELECT M.Title, string_agg(GM.Genre, ', ') AS Genres, 
	   'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer,
	   MAX(R.Rating) Ratings, MAX(R.Ratings) Ratings 
FROM Movies M
INNER JOIN Ratings_Summary R ON R.MovieID = M.MovieID
INNER JOIN Genres G on G.MovieID = M.MovieID
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
WHERE M.Year = 2000
GROUP BY M.MovieID, M.Title, M.Year
ORDER BY MAX(R.Rating) DESC, MAX(R.Ratings) DESC, M.MovieID
		

# Search by Genre Query
SELECT M.Title, M.Year, string_agg(GM.Genre, ', ') AS Genres, 
	   'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer,
	   MAX(R.Rating) Ratings, MAX(R.Ratings) Ratings 
FROM Movies M
INNER JOIN Ratings_Summary R ON R.MovieID = M.MovieID
INNER JOIN Genres G on G.MovieID = M.MovieID
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
WHERE GM.Genre = 'Fantasy'
GROUP BY M.MovieID, M.Title, M.Year
ORDER BY MAX(R.Rating) DESC, MAX(R.Ratings) DESC, M.MovieID


# Search by Rating Query
SELECT M.Title, M.Year, string_agg(GM.Genre, ', ') AS Genres, 
	   'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer,
	   MAX(R.Rating) Ratings, MAX(R.Ratings) Ratings 
FROM Movies M
INNER JOIN Ratings_Summary R ON R.MovieID = M.MovieID
INNER JOIN Genres G on G.MovieID = M.MovieID
INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
WHERE R.Rating BETWEEN 4.5 AND 5.0
GROUP BY M.MovieID, M.Title, M.Year
ORDER BY MAX(R.Rating) DESC, MAX(R.Ratings) DESC, M.MovieID

*/