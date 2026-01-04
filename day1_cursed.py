# example of Advent of Code, part 1 and 2, without using and multiplication or division
# to replicate limitations found on the ATTiny85
def main():
    current_digit = 50
    zero_landings = 0
    zero_crossings = 0

    with(open("./input.txt", "r")) as fp:
        chars = fp.read() + '\0' # emulate the end of data in the Flash
        row_buf = [0,0,0,0]
        byte_count = 0
        i = 0
        while True:
            c = chars[i]
            if c == '\n' or c == '\0':
                # process the row buffer
                if byte_count == 2:
                    # only 1 digit
                    number_of_clicks = row_buf[1]
                elif byte_count == 3:
                    # 2 digits
                    number_of_clicks = (row_buf[1] << 3) + (row_buf[1] << 1) + row_buf[2]
                else:
                    # 3 digits
                    number_of_clicks = (row_buf[2] << 3) + (row_buf[2] << 1) + row_buf[3]
                    number_of_full_rotations = row_buf[1]
                    zero_crossings += number_of_full_rotations

                # L = 28 and R = 34
                while number_of_clicks != 0:
                    if row_buf[0] == 28: # left, subtract
                        if current_digit == 0:
                            current_digit = 99
                        else:
                            current_digit -= 1
                    else: # right, add
                        if current_digit == 99:
                            current_digit = 0
                        else:
                            current_digit += 1
                    # at the end of a single tick, check if we're now on zero
                    # count if we are
                    if current_digit == 0:
                        zero_crossings += 1

                    number_of_clicks -= 1 

                if current_digit == 0:
                    zero_landings += 1

                # reset pointer in to the row buffer
                byte_count = 0
                if c == '\0':
                    print(f"zero landings: {zero_landings}")
                    print(f"zero crossing: {zero_crossings}")
                    exit()
            else:
                row_buf[byte_count] = ord(c) - 0x30
                byte_count += 1
            i += 1

if __name__ == "__main__":
    main()