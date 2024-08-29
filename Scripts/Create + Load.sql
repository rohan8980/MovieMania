----======= M O V I E S =======----
CREATE TEMPORARY TABLE IF NOT EXISTS Movies_temp (
    MovieId VARCHAR(1000),
    Title VARCHAR(1000),
    Genres VARCHAR(1000)
);

COPY Movies_temp 
FROM 'D:\UB\Sem 2\CSE 560 - Data Models and Query Language\Project\Dataset\Movies.csv' 
DELIMITER '~'
encoding 'windows-1251';

--SELECT * FROM Movies_temp ORDER BY MovieId;
DELETE FROM Movies_temp where MovieId = 'movieId';
ALTER TABLE Movies_temp ALTER COLUMN MovieId TYPE BIGINT USING MovieId::BIGINT;
--SELECT * FROM Movies_temp ORDER BY MovieId;

CREATE TABLE IF NOT EXISTS Movies (
    MovieId BIGINT PRIMARY KEY,
    title VARCHAR(1000) NOT NULL,
    genres VARCHAR(1000)
);

INSERT INTO Movies (MovieId, Title, Genres)
SELECT DISTINCT MovieId, Title, Genres
FROM Movies_temp
WHERE NOT EXISTS (SELECT 1 FROM Movies M WHERE M.MovieId = Movies_temp.MovieId)
ORDER BY MovieId;

DROP TABLE IF EXISTS Movies_temp;




----======= L I N K S =======----
CREATE TEMPORARY TABLE IF NOT EXISTS Links_temp (
    MovieID VARCHAR(100),
    ImdbID VARCHAR(100),
    TmdbID VARCHAR(100)
);

COPY Links_temp 
FROM 'D:\UB\Sem 2\CSE 560 - Data Models and Query Language\Project\Dataset\links.csv'  
DELIMITER ','
encoding 'windows-1251';

--SELECT * FROM Links_temp ORDER BY MovieID;
DELETE FROM Links_temp WHERE MovieID = 'movieId';
ALTER TABLE Links_temp ALTER COLUMN MovieID TYPE BIGINT USING MovieID::BIGINT;
--SELECT * FROM Links_temp ORDER BY MovieID;

CREATE TABLE IF NOT EXISTS Links (
    LinksID BIGSERIAL PRIMARY KEY,
    MovieID BIGINT,
    ImdbID VARCHAR(1000),
    TmdbID VARCHAR(100),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);

INSERT INTO Links (MovieID, ImdbID, TmdbID)
SELECT DISTINCT MovieID, ImdbID, TmdbID
FROM Links_temp
WHERE NOT EXISTS (SELECT 1 FROM Links L WHERE L.MovieID = Links_temp.MovieID)
ORDER BY MovieID;

DROP TABLE IF EXISTS Links_temp;




----======= T A G S =======----
CREATE TEMPORARY TABLE IF NOT EXISTS Tags_temp (
    UserID VARCHAR(100),
    MovieID VARCHAR(100),
    TagID VARCHAR(1000),
    recTimestamp VARCHAR(500)
);

COPY Tags_temp 
FROM 'D:\UB\Sem 2\CSE 560 - Data Models and Query Language\Project\Dataset\tags.csv'  
DELIMITER ','
QUOTE '"'
CSV Header;

-- SELECT * FROM Tags_temp ORDER BY UserID, MovieID;
ALTER TABLE Tags_temp ALTER COLUMN UserID TYPE BIGINT USING UserID::BIGINT;
ALTER TABLE Tags_temp ALTER COLUMN MovieID TYPE BIGINT USING MovieID::BIGINT;
-- SELECT * FROM Tags_temp ORDER BY UserID, MovieID;

CREATE TABLE IF NOT EXISTS Tags (
    ID BIGSERIAL PRIMARY KEY,
    UserID BIGINT,
    MovieID BIGINT,
    TagID VARCHAR(1000),
    recTimestamp VARCHAR(500),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);

INSERT INTO Tags (UserID, MovieID, TagID, recTimestamp)
SELECT DISTINCT UserID, MovieID, TagID, recTimestamp
FROM Tags_temp
WHERE NOT EXISTS (SELECT 1 FROM Tags T WHERE T.UserID = Tags_temp.UserID AND T.MovieID = Tags_temp.MovieID AND T.TagID = Tags_temp.TagID)
ORDER BY UserID, MovieID;

DROP TABLE IF EXISTS Tags_temp;






----======= R A T I N G S =======----
CREATE TEMPORARY TABLE IF NOT EXISTS Ratings_temp (
    UserID VARCHAR(100),
    MovieID VARCHAR(100),
    Rating VARCHAR(1000),
    recTimestamp VARCHAR(500)
);

COPY Ratings_temp 
FROM 'D:\UB\Sem 2\CSE 560 - Data Models and Query Language\Project\Dataset\Ratings.csv' 
DELIMITER ','
CSV Header

--SELECT * FROM Ratings_temp ORDER BY UserID, MovieID LIMIT 100;
ALTER TABLE Ratings_temp ALTER COLUMN UserID TYPE BIGINT USING UserID::BIGINT;
ALTER TABLE Ratings_temp ALTER COLUMN MovieID TYPE BIGINT USING MovieID::BIGINT;
ALTER TABLE Ratings_temp ALTER COLUMN Rating TYPE FLOAT USING Rating::FLOAT;
--SELECT * FROM Ratings_temp ORDER BY UserID, MovieID LIMIT 100;

CREATE TABLE IF NOT EXISTS Ratings (
    UserID BIGINT,
    MovieID BIGINT,
    Rating FLOAT,
    recTimestamp VARCHAR(500),
    PRIMARY KEY (UserID, MovieID),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);

INSERT INTO Ratings (UserID, MovieID, Rating, recTimestamp)
SELECT DISTINCT UserID, MovieID, Rating, recTimestamp
FROM Ratings_temp
WHERE NOT EXISTS (SELECT 1 FROM Ratings R WHERE R.UserID = Ratings_temp.UserID AND R.MovieID = Ratings_temp.MovieID AND R.Rating = Ratings_temp.Rating)
ORDER BY UserID, MovieID;

DROP TABLE IF EXISTS Ratings_temp;



----======= Y O U T U B E =======----
CREATE TEMPORARY TABLE IF NOT EXISTS Youtube_temp (
    YoutubeID VARCHAR(100),
    MovieID VARCHAR(100),
    Title VARCHAR(1000)
);

COPY Youtube_temp 
FROM 'D:\UB\Sem 2\CSE 560 - Data Models and Query Language\Project\Dataset\ml-youtube.csv' 
DELIMITER ','
QUOTE '"'
CSV Header;

--SELECT * FROM Youtube_temp ORDER BY MovieID;
ALTER TABLE Youtube_temp ALTER COLUMN MovieID TYPE BIGINT USING MovieID::BIGINT;
UPDATE Youtube_temp SET Title = REPLACE(Title, '"', '');
--SELECT * FROM Youtube_temp ORDER BY MovieID;

CREATE TABLE IF NOT EXISTS Youtube (
    ID BIGSERIAL PRIMARY KEY,
    YoutubeID VARCHAR(100),
    MovieID BIGINT,
    Title VARCHAR(1000),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);

INSERT INTO Youtube (YoutubeID, MovieID, Title)
SELECT YoutubeID, MovieID, Title
FROM Youtube_temp
WHERE NOT EXISTS (SELECT 1 FROM Youtube Y WHERE Y.MovieID = Youtube_temp.MovieID)
ORDER BY MovieID;

DROP TABLE IF EXISTS Youtube_temp;


ALTER TABLE Youtube DROP COLUMN Title;




----======= G E N R E  -  M A S T E R =======----
CREATE TEMPORARY TABLE Genres_temp AS
SELECT M.MovieId, g.Value
FROM Movies M
CROSS JOIN unnest(string_to_array(M.genres, '|')) as g(Value);

CREATE TABLE IF NOT EXISTS Genres_Master (
    ID SERIAL PRIMARY KEY,
    Genre VARCHAR(100)
);

INSERT INTO Genres_Master (Genre)
SELECT DISTINCT Value 
FROM Genres_temp
ORDER BY Value;

----======= G E N R E S =======----
CREATE TABLE IF NOT EXISTS Genres (
    MovieID BIGINT,
    GenreID INT,
    PRIMARY KEY (MovieID, GenreID),
    FOREIGN KEY (MovieID) REFERENCES Movies (MovieID),
    FOREIGN KEY (GenreID) REFERENCES Genres_Master (ID)
);

INSERT INTO Genres (MovieID, GenreID)
SELECT DISTINCT G.MovieId, M.ID AS GenreID
FROM Genres_temp G
LEFT JOIN Genres_Master M ON G.Value = M.Genre
ORDER BY G.MovieId, M.ID;


ALTER TABLE Movies DROP COLUMN genres;
DROP TABLE IF EXISTS Genres_temp;





----======= T A G S  -  M A S T E R =======----
CREATE TABLE IF NOT EXISTS Tags_Master (
    ID SERIAL PRIMARY KEY,
    Tag VARCHAR(1000)
);

INSERT INTO Tags_Master (Tag)
SELECT DISTINCT TagID
FROM Tags
ORDER BY TagID;


CREATE TEMPORARY TABLE TagID_Update AS
SELECT T.ID, TM.ID AS TagID_New
FROM Tags T
INNER JOIN Tags_Master TM ON T.TagID = TM.Tag;

UPDATE Tags 
SET TagID = U.TagID_New
FROM TagID_Update U
WHERE Tags.ID = U.ID;


ALTER TABLE Tags ALTER COLUMN TagID TYPE INT USING TagID::INT;
ALTER TABLE Tags ADD CONSTRAINT FK_Tags_Master FOREIGN KEY (TagID) REFERENCES Tags_Master(ID);





----======= MERGING Links And Youtube With Movies ======----
CREATE TEMPORARY TABLE Movies_temp AS
SELECT Movies.MovieId, Title, ImdbID, TmdbID, YoutubeID
FROM Movies
LEFT JOIN Links ON Links.MovieID = Movies.MovieId
LEFT JOIN Youtube ON Youtube.MovieID = Movies.MovieId;


ALTER TABLE Movies ADD COLUMN ImdbID VARCHAR(100);
ALTER TABLE Movies ADD COLUMN TmdbID VARCHAR(100);
ALTER TABLE Movies ADD COLUMN YoutubeID VARCHAR(100);

UPDATE Movies M
SET ImdbID = T.ImdbID,
    TmdbID = T.TmdbID,
    YoutubeID = T.YoutubeID
FROM Movies_temp T
WHERE M.MovieId = T.MovieId;

DROP TABLE IF EXISTS Movies_temp;

CREATE TABLE Links_Bkp AS SELECT * FROM Links;
CREATE TABLE Youtube_Bkp AS SELECT * FROM Youtube;
DROP TABLE IF EXISTS Links;
DROP TABLE IF EXISTS Youtube;



----======= M O V I E L I N K S =======----
CREATE TABLE IF NOT EXISTS MovieLinks (
    ID BIGSERIAL PRIMARY KEY,
    MovieID BIGINT,
    ImdbLink VARCHAR(100),
    TmdbLink VARCHAR(100),
    YoutubeLink VARCHAR(100),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);

INSERT INTO MovieLinks (MovieID, ImdbLink, TmdbLink, YoutubeLink)
SELECT M.MovieId,
       'http://www.imdb.com/title/tt' || LTRIM(RTRIM(L.ImdbID)) ImdbLink,
       'https://www.themoviedb.org/movie/' || LTRIM(RTRIM(L.TmdbID)) TmdbLink,
       'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(Y.YoutubeID)) YoutubeLink
FROM Movies M
LEFT JOIN Links_Bkp L ON L.MovieID = M.MovieId
LEFT JOIN Youtube_Bkp Y ON Y.MovieID = M.MovieId
ORDER BY M.MovieId;