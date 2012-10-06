module nbd;

private {
    import std.stream : Stream, BufferedFile, EndianStream, FileMode;
    import std.system : Endian;
    import std.file : exists;
    import std.exception : enforceEx;
    import std.typetuple : TypeTuple;
    import std.typecons : NoDuplicates;
    import std.traits : isArray, isStaticArray;
    import std.string : format;
    import std.metastrings : toStringNow;

    import std.stdio;
}


class NBTException : Exception {
    this(string s, string f=__FILE__, size_t l=__LINE__) {
        super(s, f, l);
    }
}


class NBTFile : TAG_Compound {
    enum Compression {
        NONE,
        GZIP,
        DEFLATE,
        AUTO
    }

    this()() {}

    this()(string file, Compression compression = Compression.AUTO, bool big_endian = true) {
        this(new BufferedFile(file, FileMode.In), compression, big_endian);
    }

    this()(Stream stream, Compression compression = Compression.AUTO, bool big_endian = true) {
        Endian endian = big_endian ? Endian.bigEndian : Endian.littleEndian;
        stream = new EndianStream(stream, Endian.bigEndian);

        read(stream);
    }

    private void read(Stream stream) {
        enforceEx!NBTException(stream.readable, "Can't read from stream");

        enforceEx!NBTException(.read!(byte)(stream) == 0x0A, "file doesn't start with TAG_Compound");

        TAG_Compound tc = super.read(stream);

        _value.compound = tc.value;
        name = tc.name;
    }

    void save(Stream stream, Compression compression = Compression.DEFLATE, bool big_endian = true) {
        enforceEx!NBTException(stream.writeable, "Can't write into stream");

        Endian endian = big_endian ? Endian.bigEndian : Endian.littleEndian;
        stream = new EndianStream(stream, Endian.bigEndian);
    }    
}

union Value {
    byte byte_;
    short short_;
    int int_;
    long long_;
    float float_;
    double double_;
    byte[] byte_array;
    string string_;
    TAG[] list;
    TAG[string] compound;
    int[] int_array;
}

mixin template _TAG_Ctor() {
    this(T)(string name, T value) {
        this.name = name;
        set(value);
    }

    @property auto value() {
        return get!(id)();
    }

    string toString() {
        return "%s(%s, %s)".format(typeof(this).stringof, name, value);
    }
}


abstract class TAG {
    enum id = 0;

    protected Value _value;
    string name;
   
    void write(Stream) {
        throw new NBTException("write not implemented");
    }

    static TAG read(Stream) {
        throw new NBTException("read not implemented");
    }

    auto get(int id)() {
        static if(id == 1) {
            return _value.byte_;
        } else static if(id == 2) {
            return _value.short_;
        } else static if(id == 3) {
            return _value.int_;
        } else static if(id == 4) {
            return _value.long_;
        } else static if(id == 5) {
            return _value.float_;
        } else static if(id == 6) {
            return _value.double_;
        } else static if(id == 7) {
            return _value.byte_array;
        } else static if(id == 8) {
            return _value.string_;
        } else static if(id == 9) {
            return _value.list;
        } else static if(id == 10) {
            return _value.compound;
        } else static if(id == 11) {
            return _value.int_array;
        } else {
            static assert(false, "get not implemented for id " ~ toStringNow!(i));
        }
    }

    void set(T)(T value) {
        static if(is(T == byte)) {
            _value.byte_ = value;
        } else static if(is(T == short)) {
            _value.short_ = value;
        } else static if(is(T == int)) {
            _value.int_ = value;
        } else static if(is(T == long)) {
            _value.long_ = value;
        } else static if(is(T == float)) {
            _value.float_ = value;
        } else static if(is(T == double)) {
            _value.double_ = value;
        } else static if(is(T == byte[])) {
            _value.byte_array = value;
        } else static if(is(T == string)) {
            _value.string_ = value;
        } else static if(is(T == TAG[])) {
            _value.list = value;
        } else static if(is(T == TAG[string])) {
            _value.compound = value;
        } else static if(is(T == int[])) {
            _value.int_array = value;
        } else {
            static assert(false, "set not implemented for " ~ T.stringof);
        }
    }
}

private template Enumeration(int i_, T) {
    enum i = i_;
    alias T Type;
}

private template get_tags() {
    alias NoDuplicates!(get_tags_impl!(__traits(allMembers, mixin(.stringof[7..$])))) get_tags;
}

private template get_tags_impl(T...) {
    static if(T.length == 0) {
        alias TypeTuple!() get_tags_impl;
    } else static if(T[0].length > 4 && T[0][0..4] == "TAG_" /+&& is(` ~ T[0] ~ ` : TAG)+/) {
        alias TypeTuple!(Enumeration!(mixin(T[0]).id, mixin(T[0])), get_tags_impl!(T[1..$])) get_tags_impl;
    } else {
        alias get_tags_impl!(T[1..$]) get_tags_impl;
    }
}

alias get_tags!() _tags;
debug pragma(msg, _tags);


class TAG_Byte : TAG {
    enum id = 1;

    mixin _TAG_Ctor!();

    static TAG_Byte read(Stream stream, bool no_name = false) {
        return new TAG_Byte(no_name ? "" : .read!string(stream), .read!byte(stream));
    }
}

class TAG_Short : TAG {
    enum id = 2;

    mixin _TAG_Ctor!();

    static TAG_Short read(Stream stream, bool no_name = false) {
        return new TAG_Short(no_name ? "" : .read!string(stream), .read!byte(stream));
    }
}

class TAG_Int : TAG {
    enum id = 3;

    mixin _TAG_Ctor!();

    static TAG_Int read(Stream stream, bool no_name = false) {
        return new TAG_Int(no_name ? "" : .read!string(stream), .read!byte(stream));
    }
}

class TAG_Long : TAG {
    enum id = 4;

    mixin _TAG_Ctor!();

    static TAG_Long read(Stream stream, bool no_name = false) {
        return new TAG_Long(no_name ? "" : .read!string(stream), .read!byte(stream));
    }
}

class TAG_Float : TAG {
    enum id = 5;

    mixin _TAG_Ctor!();

    static TAG_Float read(Stream stream, bool no_name = false) {
        return new TAG_Float(no_name ? "" : .read!string(stream), .read!byte(stream));
    }
}

class TAG_Double : TAG {
    enum id = 6;

    mixin _TAG_Ctor!();

    static TAG_Double read(Stream stream, bool no_name = false) {
        return new TAG_Double(no_name ? "" : .read!string(stream), .read!byte(stream));
    }
}

class TAG_Byte_Array : TAG {
    enum id = 7;

    mixin _TAG_Ctor!();

    static TAG_Byte_Array read(Stream stream, bool no_name = false) {
        return new TAG_Byte_Array(no_name ? "" : .read!string(stream), .read!(byte[])(stream));
    }
}

class TAG_String : TAG {
    enum id = 8;

    mixin _TAG_Ctor!();

    static TAG_String read(Stream stream, bool no_name = false) {
        return new TAG_String(no_name ? "" : .read!string(stream), .read!string(stream));
    }
}

class TAG_List : TAG {
    enum id = 9;

    mixin _TAG_Ctor!();

    static TAG_List read(Stream stream, bool no_name = false) {
        string name = no_name ? "" : .read!string(stream);

        byte tag = .read!byte(stream);
        TAG[] result;
        result.length = .read!int(stream);

        sw:
        switch(tag) {
            foreach(e; _tags) {
                case e.i: {
                    foreach(i; 0..result.length) {
                        result[i] = e.Type.read(stream, false);
                    }
                    
                    break sw;
                }
            }

            default: throw new NBTException(`invalid/unimplemented tag value %d"`.format(tag));
        }
    }
}

class TAG_Compound : TAG {
    enum id = 10;

    mixin _TAG_Ctor!();

    static TAG_Compound read(Stream stream, bool no_name = false) {
        TAG[string] result;

        string name = no_name ? "" : .read!string(stream);

        parse:
        while(true) {
            byte tag = .read!(byte)(stream);

            sw:
            switch(tag) {
                case 0: break parse; break;

                foreach(e; _tags) {
                    case e.i: e.Type tmp = e.Type.read(stream, false);
                              result[tmp.name] = tmp;
                              break sw;
                }

                default: throw new NBTException(`invalid/unimplemented tag value %d"`.format(tag));
            }

        }

        return new TAG_Compound(name, result);
    }
}

class TAG_Int_Array : TAG {
    enum id = 11;

    mixin _TAG_Ctor!();

    static TAG_Int_Array read(Stream stream, bool no_name = false) {
        return new TAG_Int_Array(no_name ? "" : .read!string(stream), .read!(int[])(stream));
    }
}



T read(T)(Stream stream) {
    static if(__traits(hasMember, T, "read")) {
        return T.read(stream);
    } else  {
        return read_impl!(T)(stream);
    }
}

private T read_impl(T)(Stream stream) if(is(T == string)) {
    ushort length = read!(ushort)(stream);
    return stream.readString(length).idup;
}

private T read_impl(T)(Stream stream) if(!is(T == string)) {
    static if(isArray!T) {
        static if(isStaticArray!T) {
            T ret;
        } else {
            T ret;
            ret.length = .read!int(stream);
        }
        
        foreach(i; 0..ret.length) {
            stream.read(ret[i]);
        }

        return ret;
    } else {
        T res;  
        stream.read(res);
        return res;
    }
}
