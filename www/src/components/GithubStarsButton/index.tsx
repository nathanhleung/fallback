/**
 * Based on https://github.com/trpc/trpc/blob/main/www/src/components/GithubStarsButton.tsx
 */

import Link from "@docusaurus/Link";
import clsx from "clsx";
import React, { useEffect, useState } from "react";
import styles from "./styles.module.css";

export const GithubStarsButton = () => {
  const [stars, setStars] = useState<string>();

  const fetchStars = async () => {
    const res = await fetch(
      "https://api.github.com/repos/nathanhleung/fallback"
    );
    const data = await res.json();
    if (typeof data?.stargazers_count === "number") {
      setStars(new Intl.NumberFormat().format(data.stargazers_count));
    }
  };

  useEffect(() => {
    fetchStars().catch(console.error);
  }, []);

  return (
    <Link
      href="https://github.com/nathanhleung/fallback/stargazers"
      target="_blank"
      className="button button--secondary button--lg"
    >
      <div className={styles.githubStarsButton}>
        <div className="flex">
          <svg
            stroke="currentColor"
            fill="none"
            strokeWidth="3"
            viewBox="0 0 24 24"
            strokeLinecap="round"
            strokeLinejoin="round"
            height="18"
            width="18"
            xmlns="http://www.w3.org/2000/svg"
          >
            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
          </svg>
        </div>
        <span>Star</span>
        <span
          style={{ transition: "max-width 1s, opacity 1s" }}
          className={clsx(
            "whitespace-nowrap overflow-hidden w-full",
            stars ? "opacity-100 max-w-[100px]" : "opacity-0 max-w-0"
          )}
        >
          {stars}
        </span>
      </div>
    </Link>
  );
};
