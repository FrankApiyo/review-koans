def last_error(jobs):
    error = None
    for job in jobs:
        try:
            job()
        except ZeroDivisionError as error:
            pass
    return error


print(last_error([lambda: 1 / 0]))
