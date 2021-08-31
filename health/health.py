import schedule
from tkinter import messagebox


def main():
    schedule.every().hours.do(job)
    while True:
        schedule.run_pending()


def job():
    messagebox.showwarning("warning", "Take a break!")


main()
