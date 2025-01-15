-- Easy
-- Q1. List all unique candidates who participated in the elections.

SELECT DISTINCT(candidate)
FROM constituencywise_details;

-- Q2. List all candidates who secured votes between 30% and 50%. Along with their party names.

SELECT candidate, party, percentage_of_votes
FROM constituencywise_details
WHERE percentage_of_votes BETWEEN 30 AND 50;

-- Q3. Find the second-highest winning margin.

SELECT *
FROM constituencywise_results
ORDER BY margin DESC
LIMIT 1 OFFSET 1;

-- Q4. Count the number of constituencies in each state.

SELECT state, COUNT(*)
FROM statewise_results
GROUP BY 1
ORDER BY 2 DESC;

-- There’s a mistake in the data where many other state's constituencies are listed under Himachal Pradesh, causing the total to incorrectly add up to 416. We need to fix this first.

ALTER TABLE statewise_results
ALTER COLUMN state TYPE VARCHAR(50);

UPDATE statewise_results
SET state = CASE
				WHEN state_id = 'U01' THEN 'Andaman & Nicobar Islands'
				WHEN state_id = 'U02' THEN 'Chandigarh'
				WHEN state_id = 'S26' THEN 'Chhattisgarh'
				WHEN state_id = 'U03' THEN 'Dadra & Nagar Haveli and Daman & Diu'
				WHEN state_id = 'U08' THEN 'Jammu and Kashmir'
				WHEN state_id = 'S27' THEN 'Jharkhand'
				WHEN state_id = 'S10' THEN 'Karnataka'
				WHEN state_id = 'S11' THEN 'Kerala'
				WHEN state_id = 'U09' THEN 'Ladakh'
				WHEN state_id = 'S12' THEN 'Madhya Pradesh'
				WHEN state_id = 'S13' THEN 'Maharashtra'
				WHEN state_id = 'S14' THEN 'Manipur'
				WHEN state_id = 'S15' THEN 'Meghalaya'
				WHEN state_id = 'S16' THEN 'Mizoram'
				WHEN state_id = 'S17' THEN 'Nagaland'
				WHEN state_id = 'S18' THEN 'Odisha'
				WHEN state_id = 'S19' THEN 'Punjab'
				WHEN state_id = 'S20' THEN 'Rajasthan'
				WHEN state_id = 'S21' THEN 'Sikkim'
				WHEN state_id = 'S22' THEN 'Tamil Nadu'
				WHEN state_id = 'S29' THEN 'Telangana'
				WHEN state_id = 'S23' THEN 'Tripura'
				WHEN state_id = 'S24' THEN 'Uttar Pradesh'
				WHEN state_id = 'S28' THEN 'Uttarakhand'
				WHEN state_id = 'S25' THEN 'West Bengal'
				WHEN state_id = 'U05' THEN 'Delhi'
            END
WHERE state_id IN ('U01', 'U02', 'S26', 'U03', 'U08', 'S27', 'S10', 'S11', 'U09', 'S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20', 'S21', 'S22', 'S29', 'S23', 'S24', 'S28', 'S25', 'U05');

-- Now lets find it.

SELECT state, COUNT(*)
FROM statewise_results
GROUP BY 1
ORDER BY 2 DESC;

-- Q5. List the top 3 parties with the most total votes across all constituencies.

SELECT party, SUM(total_votes)
FROM constituencywise_details
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- Moderate
-- Q6. -- Identify top 5 constituencies with the largest difference in votes between the winning and trailing candidates.

SELECT constituency, margin
FROM statewise_results
ORDER BY margin DESC
LIMIT 5;

-- Q7.  Rank the parties based on their total votes across all states, using window functions.

SELECT party, SUM(total_votes) AS Total_Votes,
       RANK() OVER (ORDER BY SUM(total_votes) DESC) AS Party_Rank
FROM constituencywise_details
GROUP BY party;

-- Q8. Retrieve the party and total votes for all constituencies in a specific state (e.g., 'Maharashtra').

SELECT cd.party, SUM(cd.total_votes) as total_votes
FROM constituencywise_details cd
JOIN constituencywise_results cr ON cr.constituency_id = cd.constituency_id
JOIN statewise_results sr ON sr.parliament_constituency = cr.parliament_constituency
WHERE sr.state = 'Maharashtra'
GROUP BY 1
ORDER BY 2 DESC;

-- Q9. Identify states where the total number of constituencies is above the national average.

SELECT state, COUNT(*) AS  total_constituency
FROM statewise_results
GROUP BY state
HAVING COUNT(*) > (SELECT AVG(constituency_count)
							FROM
								(SELECT state, COUNT(*) as constituency_count
								FROM statewise_results
								GROUP BY state)
							);

-- Q10. Calculate the average percentage of votes received by candidates in each state.

SELECT sr.state, ROUND(AVG(cd.percentage_of_votes)::NUMERIC, 2)
FROM statewise_results sr
JOIN constituencywise_results cr ON cr.parliament_constituency = sr.parliament_constituency
JOIN constituencywise_details cd ON cd.constituency_id = cr.constituency_id
GROUP BY 1
ORDER BY 2 DESC;

-- Moderate
-- Q11. Identify the constituencies where the winner received less than 40% of total votes.

WITH TotalVotesPerConstituency AS (
									SELECT constituency_id, SUM(total_votes) AS total_constituency_votes
									FROM constituencywise_details
									GROUP BY 1
									)
SELECT cr.constituency_id, cr.winning_candidate, cr.total_votes AS winner_votes, tv.total_constituency_votes
FROM constituencywise_results cr
JOIN TotalVotesPerConstituency tv
	ON tv.constituency_id = cr.constituency_id
WHERE cr.total_votes < 0.4 * tv.total_constituency_votes
;

-- Q12. Determine the party that came second most frequently in all constituencies.

WITH RankedResults AS
(
    SELECT 
        constituency_id,
        party,
        RANK() OVER (PARTITION BY constituency_id ORDER BY percentage_of_votes DESC) AS rank
    FROM constituencywise_details
)
SELECT party, COUNT(*) AS frequency
FROM RankedResults
WHERE rank = 2
GROUP BY 1
ORDER BY frequency DESC
LIMIT 1;

-- Q13. Find the cumulative total votes for each state.

SELECT sr.state, SUM(cd.total_votes)
FROM statewise_results sr
JOIN constituencywise_results cr
	ON cr.parliament_constituency = sr.parliament_constituency
JOIN constituencywise_details cd
	ON cd.constituency_id = cr.constituency_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q14. Identify constituencies with the smallest winning margin as a percentage of total votes.

SELECT constituency_name, margin, total_votes, 
      ROUND((margin * 100.0 / total_votes), 2) AS Margin_Percentage 
FROM constituencywise_results
WHERE total_votes > 0 -- Because there are some zero values also.
ORDER BY Margin_Percentage ASC 
LIMIT 5;

-- Q15. Create a state-wise summary showing the party with the highest total votes in each state.

SELECT state, party, total_votes
FROM (
	SELECT 
		sr.state,
		cd.party,
		SUM(cd.total_votes) as total_votes,
		RANK() OVER(PARTITION BY sr.state ORDER BY SUM(cd.total_votes) DESC) AS rank
	FROM statewise_results sr
	JOIN constituencywise_results cr
		ON cr.parliament_constituency = sr.parliament_constituency
	JOIN constituencywise_details cd
		ON cd.constituency_id = cr.constituency_id
	GROUP BY 1, 2
	) AS StatePartyVotes
WHERE rank = 1
ORDER BY 3 DESC;

-- Thanks!!