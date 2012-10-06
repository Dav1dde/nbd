module nbd;

private {
    import std.stream : Stream, BufferedFile, EndianStream, FileMode;
    import std.system : Endian;
    import std.file : exists;
    import std.exception : enforceEx;
    import std.typetuple : TypeTuple;
    import std.typecons : NoDuplicates;
    import std.traits : ReturnType;
    import std.string : format;

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

    protected Stream raw_stream;
    protected Endian endian;
    protected EndianStream endianstream;

    this()(string file, Compression compression = Compression.AUTO, bool big_endian = true) {
        if(file.exists()) {
            this(new BufferedFile(file, FileMode.In), compression, big_endian);
        } else {
            this(new BufferedFile(file, FileMode.OutNew), compression, big_endian);
        }
    }

    this()(Stream stream, Compression compression = Compression.AUTO, bool big_endian = true) {
        raw_stream = stream;

        endian = big_endian ? Endian.bigEndian : Endian.littleEndian;
        endianstream = new EndianStream(raw_stream, Endian.bigEndian);
    }

    void read() {
        enforceEx!NBTException(raw_stream.readable, "Can't read from stream");

        enforceEx!NBTException(.read!(byte)(endianstream) == 0x0A, "file doesn't start with TAG_Compound");

        auto tc = super.read(endianstream);

        _value.compound = tc.value;
        name = tc.name;
    }

    void write() {
        enforceEx!NBTException(raw_stream.writeable, "Can't write into stream");
    }    
}

union Value {
    TAG[string] compound;
    string string_;
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
            return _value.compound;
        } else static if(id == 8) {
            return _value.string_;
        }
    }

    void set(T)(T value) {
        static if(is(T == TAG[string])) {
            _value.compound = value;
        } else static if(is(T == string)) {
            _value.string_ = value;
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

class TAG_Compound : TAG {
    enum id = 1;

    mixin _TAG_Ctor!();

    static TAG_Compound read(Stream stream) {
        TAG[string] result;

        string name = .read!string(stream);

        parse:
        while(true) {
            byte tag = .read!(byte)(stream);

            sw:
            switch(tag) {
                case 0: break parse; break;

                foreach(e; _tags) {
                    case e.i: e.Type tmp = e.Type.read(stream);
                              result[tmp.name] = tmp;
                              break sw;
                }

                default: throw new NBTException(`invalid/unimplemented tag value %d"`.format(tag));
            }

        }

        return new TAG_Compound(name, result);
    }
}

class TAG_String : TAG {
    enum id = 8;

    mixin _TAG_Ctor!();

    static TAG_String read(Stream stream) {
        return new TAG_String(.read!string(stream), .read!string(stream));
    }
}



T read(T)(Stream stream) {
    static if(__traits(hasMember, T, "read")) {
        return T.read(stream);
    } else  {
        return read_impl!(T)(stream);
    }
}

private T read_impl(T : string)(Stream stream) {
    ushort length = read!(ushort)(stream);
    return stream.readString(length).idup;
}

private T read_impl(T)(Stream stream) {
    T res;
    stream.read(res);
    return res;
}
