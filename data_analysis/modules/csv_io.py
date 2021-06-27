import csv

def writeToCsv(filename, fieldnames, data_list):
    with open(filename, mode='w') as data:
        data_writer = csv.writer(data, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        writer = csv.DictWriter(data, fieldnames=fieldnames)

        writer.writeheader()
        for entry in data_list:
            data_writer.writerow(entry)

def readFromCsv(filepath):
    data = []
    with open(filepath, mode='r') as data_set:
        csv_reader = csv.DictReader(data_set)
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                line_count += 1
            data.append(row)
            line_count += 1
    return data
