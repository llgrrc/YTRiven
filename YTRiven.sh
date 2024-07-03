#!/bin/bash

# Function to check dependencies
check_dependencies() {
    command -v yt-dlp >/dev/null 2>&1 || { echo >&2 "yt-dlp is required but it's not installed. Aborting."; exit 1; }
    command -v ffmpeg >/dev/null 2>& 1 || { echo >&2 "ffmpeg is required but it's not installed. Aborting."; exit 1; }
}

# Function to download and convert YouTube video
download_video() {
    local video_url="$1"
    local format="$2"
    local location="$3"
    local title="$4"

    echo -e "\033[1;34mDownloading video: $title\033[0m"

    # Use a temporary file for the download
    temp_file="/tmp/$title.%(ext)s"
    yt-dlp --no-overwrites -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best' -o "$temp_file" "$video_url"

    if [ $? -eq 0 ]; then
        echo -e "\033[1;32mDownload successful!\033[0m"
        
        output_file="$location/$title.$format"
        case $format in
            mov)
                ffmpeg -y -i "/tmp/$title.mp4" -c:v prores -c:a pcm_s16le "$output_file"
                ;;
            mp4)
                ffmpeg -y -i "/tmp/$title.mp4" -c:v libx264 -c:a aac -strict experimental -b:a 192k "$output_file"
                ;;
            mp3)
                ffmpeg -y -i "/tmp/$title.mp4" -vn -ab 192k "$output_file"
                ;;
            *)
                echo -e "\033[1;31mInvalid format selected.\033[0m"
                return 1
                ;;
        esac

        rm "/tmp/$title.mp4"
        echo -e "\033[1;32mConversion completed: $output_file\033[0m"
        osascript -e "display notification \"$title has been downloaded and converted to $format\" with title \"YT Riven\""
    else
        echo -e "\033[1;31mDownload failed!\033[0m"
    fi
}

# Function to get YouTube video title
get_video_title() {
    local video_url="$1"
    yt-dlp --get-title "$video_url"
}

# Main script starts here
clear
check_dependencies

# Welcome message with colors
echo -e "\033[1;32m============================================\033[0m"
echo -e "\033[1;34m          Welcome to YT Riven!             \033[0m"
echo -e "\033[38;5;208m          Developed by MacBX               \033[0m"
echo -e "\033[1;32m============================================\033[0m"

echo -e "\033[1;36mEnter the YouTube URL:\033[0m"
read video_url

if ! [[ "$video_url" =~ ^https?:// ]]; then
    echo -e "\033[1;31mInvalid URL. Exiting program.\033[0m"
    exit 1
fi

# Get video title immediately to speed up the process
video_title=$(get_video_title "$video_url")
if [ -z "$video_title" ]; then
    echo -e "\033[1;31mFailed to retrieve video title. Exiting program.\033[0m"
    exit 1
fi

# Prompt for output format with clear default
echo -e "\033[1;36mSelect the output format:\033[0m"
echo -e "\033[1;33m1. MOV\033[0m"
echo -e "\033[1;33m2. MP4 (default)\033[0m"
echo -e "\033[1;33m3. MP3\033[0m"
read -p "Select an option (1/2/3): " format_choice

case ${format_choice:-2} in
    1) format="mov" ;;
    2) format="mp4" ;;
    3) format="mp3" ;;
    *) echo -e "\033[1;31mInvalid option. Exiting program.\033[0m" ; exit 1 ;;
esac

# Prompt for download location with clear default
echo -e "\033[1;36mSelect the download location:\033[0m"
echo -e "\033[1;33m1. Desktop\033[0m"
echo -e "\033[1;33m2. Downloads (default)\033[0m"
read -p "Select an option (1/2): " location_choice

case ${location_choice:-2} in
    1) location="$HOME/Desktop" ;;
    2) location="$HOME/Downloads" ;;
    *) echo -e "\033[1;31mInvalid option. Exiting program.\033[0m" ; exit 1 ;;
esac

download_video "$video_url" "$format" "$location" "$video_title"

