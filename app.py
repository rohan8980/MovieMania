import streamlit as st 
import pandas as pd
import sqlalchemy as sa
import streamlit.components.v1 as stc

# Database connection using SQLAlchemy
DATABASE_URL = "postgresql://postgres:9870@localhost/DMQL Project"
engine = sa.create_engine(DATABASE_URL)

HTML_BANNER = """
    <div style="background-color:#464e5f;padding:10px;border-radius:10px">
    <h1 style="color:white;text-align:center;">Movie Mania </h1>
    </div>
    """

def main():
    """Basics on Streamlit layout"""

    menu = ["Home", "Search", "About"]
    choice = st.sidebar.selectbox("Menu", menu)
    stc.html(HTML_BANNER)

    if choice == 'Home':
        st.subheader("Home")

        # User input for movie name
        movie_name = st.text_input("Enter Movie Name")

        # Button to trigger the search
        search_button = st.button("Search")

        if search_button and movie_name:
            # SQL query to fetch movie data based on user input
            movie_query = f"""
            SELECT T.Title, T.Genres, T.Trailer, CAST(AVG(Rating) AS NUMERIC(10,2)) AS Rating, COUNT(*) AS Ratings
            FROM (
                SELECT M.MovieID, M.Title, string_agg(GM.Genre, ', ') AS Genres, 
                    'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer
                FROM Movies M
                INNER JOIN Genres G on G.MovieID = M.MovieID
                INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
                WHERE M.Title = '{movie_name}'
                GROUP BY M.MovieID, M.Title
                ) T 
            INNER JOIN Ratings R on R.MovieID = T.MovieID
            GROUP BY T.MovieID, T.Title, T.Genres, T.Trailer
            """
            df = pd.read_sql_query(movie_query, engine)
            st.write(df)

            if not df.empty:
                # Display movie details
                st.write(f"**Title:** {df.iloc[0]['title']}")
                st.write(f"**Genres:** {df.iloc[0]['genres']}")
                st.write(f"**Average Rating:** {df.iloc[0]['rating']}")
                st.write(f"**Number of Ratings:** {df.iloc[0]['ratings']}")

                # Trailer Video Layout
                st.write("**Trailer**")
                st.video(df.iloc[0]['trailer']) 
            else:
                st.write("Movie not found.")
        elif search_button and not movie_name:
            st.warning("Please enter a movie name to search.")

    elif choice == "Search":
        st.subheader("Search Movies")

        # Search by Year
        movie_year = st.number_input("Year", 1995, 2020)

        # Button to trigger the search
        search_year_button = st.button("Search by Year")

        if search_year_button:
            # SQL query to fetch movie data based on the year
            year_query = f"""
            SELECT T.Title, T.Genres, T.Trailer, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
            FROM (
                SELECT M.MovieID, M.Title, M.Year, string_agg(GM.Genre, ', ') AS Genres, 
                    'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer
                FROM Movies M
                INNER JOIN Genres G on G.MovieID = M.MovieID
                INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
                WHERE M.Year = {movie_year}
                GROUP BY M.MovieID, M.Title
                ) T 
            INNER JOIN Ratings R on R.MovieID = T.MovieID
            GROUP BY T.MovieID, T.Title, T.Genres, T.Trailer
            """
            df_year = pd.read_sql_query(year_query, engine)
            if not df_year.empty:
                # Display movie details
                st.write(df_year)
            else:
                st.write("No movies found for the selected year.")

        # Search by Rating
        with st.expander("Search By Rating"):
            rating_range = st.slider("Rating", 0.0, 5.0, (0.0, 5.0))
            # Button to trigger the search
            search_rating_button = st.button("Search by Rating")

            if search_rating_button:
                # SQL query to fetch movie data based on the rating range
                rating_query = f"""
                SELECT T.Title, T.Year, string_agg(GM.Genre, ', ') AS Genres, MAX(T.Trailer) Trailer, MAX(T.Rating) AS AverageRating, COUNT(T.Ratings) AS TotalRatings
                FROM (
                    SELECT M.MovieID, M.Title, M.Year, CAST(AVG(Rating) AS NUMERIC(10,2)) AS Rating, COUNT(*) AS Ratings, 
                        'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer
                    FROM Movies M
                    INNER JOIN Ratings R ON R.MovieID = M.MovieID
                    GROUP BY M.MovieID, M.Title, M.Year
                    HAVING AVG(Rating) BETWEEN {rating_range[0]} AND {rating_range[1]}
                    ) T
                INNER JOIN Genres G on G.MovieID = T.MovieID
                INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
                GROUP BY T.MovieID, T.Title, T.Year
                ORDER BY MAX(T.Rating) DESC, MAX(T.Ratings) DESC
                """
                df_by_rating = pd.read_sql_query(rating_query, engine)
                if not df_by_rating.empty:
                    # Display movie details
                    st.write(df_by_rating)
                else:
                    st.write("No movies found for the selected rating range.")
        
        # Search by Genre
        with st.expander("Search By Genre"):
            # First, fetch all available genres
            genre_query = "SELECT DISTINCT Genre FROM Genres_Master"
            df_genres = pd.read_sql_query(genre_query, engine)
            selected_genre = st.selectbox("Select Genre", df_genres['genre'])

            # Button to trigger the search
            search_genre_button = st.button("Search by Genre")

            if search_genre_button:
                # SQL query to fetch movie data based on the selected genre
                genre_query = f"""
                SELECT T.Title, T.Genres, T.Trailer, CAST(AVG(Rating) AS NUMERIC(10,2)) Rating, COUNT(*) Ratings
                FROM (
                    SELECT M.MovieID, M.Title, M.Year, string_agg(GM.Genre, ', ') AS Genres, 
                        'https://www.youtube.com/watch?v=' || LTRIM(RTRIM(MAX(M.YoutubeID))) AS Trailer
                    FROM Movies M
                    INNER JOIN Genres G on G.MovieID = M.MovieID
                    INNER JOIN Genres_Master GM ON GM.ID = G.GenreID
                    WHERE GM.Genre = '{selected_genre}'
                    GROUP BY M.MovieID, M.Title
                    ) T 
                INNER JOIN Ratings R on R.MovieID = T.MovieID
                GROUP BY T.MovieID, T.Title, T.Genres, T.Trailer
                """
                df_by_genre = pd.read_sql_query(genre_query, engine)
                if not df_by_genre.empty:
                    # Display movie details
                    st.write(df_by_genre)
                else:
                    st.write("No movies found for the selected genre.")
    else:
        st.subheader("About")
        st.text("Built with Streamlit")

if __name__ == '__main__':
    main()
