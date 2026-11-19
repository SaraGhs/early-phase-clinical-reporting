# ------------------------------------------------------------------
# Program:  f_lb_alt_trajectory.R
# Purpose:  Figure 14.3.4 ALT mean change from baseline over time
#           by actual treatment, safety population
# Input:    outputs/datasets/adsl.rds, outputs/datasets/adlb.rds
# Output:   outputs/tlf/f_lb_alt_trajectory.png (static)
#           outputs/tlf/f_lb_alt_trajectory.html (interactive)
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(dplyr)
library(ggplot2)
library(plotly)
library(ggrepel)

arm_levels <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")
# Colour-blind-safe categorical palette, fixed order (one colour per arm)
arm_cols <- c("Placebo"              = "#2a78d6",
              "Xanomeline Low Dose"  = "#eb6834",
              "Xanomeline High Dose" = "#1baf7a")

saf_ids <- readRDS("outputs/datasets/adsl.rds") %>%
  filter(SAFFL == "Y") %>% pull(USUBJID)

adlb_alt <- readRDS("outputs/datasets/adlb.rds") %>%
  filter(PARAMCD == "ALT", USUBJID %in% saf_ids,
         AVISITN > 0, !is.na(CHG)) %>%
  mutate(TRTA = factor(TRTA, levels = arm_levels))

# Mean and standard error of change from baseline, per arm and week
fig_data <- adlb_alt %>%
  group_by(TRTA, AVISITN) %>%
  summarise(n = n(), mean = mean(CHG), se = sd(CHG) / sqrt(n),
            .groups = "drop")

arm_short <- c("Placebo"              = "Placebo",
               "Xanomeline Low Dose"  = "Low dose",
               "Xanomeline High Dose" = "High dose")

last_pts <- fig_data %>%
  group_by(TRTA) %>%
  filter(AVISITN == max(AVISITN)) %>%
  mutate(lab = arm_short[as.character(TRTA)])

dodge <- position_dodge(width = 0.8)

p <- ggplot(fig_data, aes(AVISITN, mean, colour = TRTA, group = TRTA)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_errorbar(aes(ymin = mean - se, ymax = mean + se),
                width = 0.6, linewidth = 0.5, position = dodge) +
  geom_line(linewidth = 0.7, position = dodge) +
  geom_point(size = 2.5, position = dodge) +
  scale_colour_manual(values = arm_cols) +
  scale_x_continuous(breaks = sort(unique(fig_data$AVISITN)),
                     expand = expansion(mult = c(0.03, 0.18))) +
  labs(
    title    = "ALT: mean change from baseline over time",
    subtitle = "Safety population, actual treatment. Mean ± 1 SE",
    x = "Week", y = "Change from baseline (U/L)", colour = NULL,
    caption  = "Source: ADLB, ADSL. Program: programs/f_lb_alt_trajectory.R"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(),
        plot.title.position = "plot")

p_static <- p +
  geom_text_repel(data = last_pts, aes(label = lab),
                  nudge_x = 1.5, hjust = 0, direction = "y",
                  min.segment.length = 0, segment.colour = "grey70",
                  size = 3.4, colour = "grey20", show.legend = FALSE)

ggsave("outputs/tlf/f_lb_alt_trajectory.png", p_static,
       width = 9, height = 5.5, dpi = 300)

# Interactive version: legend + hover tooltips identify the arms
htmlwidgets::saveWidget(ggplotly(p), "outputs/tlf/f_lb_alt_trajectory.html",
                        selfcontained = TRUE)
unlink("outputs/tlf/f_lb_alt_trajectory_files", recursive = TRUE)

print(p_static)
